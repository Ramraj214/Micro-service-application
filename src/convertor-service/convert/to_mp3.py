import json, tempfile, os
from bson.objectid import ObjectId
from moviepy.video.io.VideoFileClip import VideoFileClip
import pika  # Import pika

def start(message, fs_videos, fs_mp3s, channel):
    try:
        message = json.loads(message)

        # Create a temporary file for the video content
        with tempfile.NamedTemporaryFile(delete=False) as tf:
            # Retrieve video content from GridFS
            out = fs_videos.get(ObjectId(message["video_fid"]))
            # Write video content to the temporary file
            tf.write(out.read())
            tf_path = tf.name

        # Convert video to audio
        audio = VideoFileClip(tf_path).audio
        audio_path = tempfile.gettempdir() + f"/{message['video_fid']}.mp3"
        audio.write_audiofile(audio_path)

        # Save the audio file to MongoDB GridFS
        with open(audio_path, "rb") as f:
            data = f.read()
            fid = fs_mp3s.put(data)
        os.remove(audio_path)

        # Update the message with the mp3 file ID
        message["mp3_fid"] = str(fid)

        # Publish the message to the specified RabbitMQ queue
        channel.basic_publish(
            exchange="",
            routing_key=os.environ.get("MP3_QUEUE"),
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE
            ),
        )
        os.remove(tf_path)
    except Exception as err:
        print(f"Error: {err}")
        return "failed to process message"
