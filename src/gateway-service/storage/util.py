import pika, json
import os

def upload(f, fs, channel, access):
    try:
        fid = fs.put(f)
    except Exception as err:
        print(err)
        return "internal server error, fs level", 500

    message = {
        "video_fid": str(fid),
        "mp3_fid": None,
        "username": access["username"],
    }

    try:
        # Declare the queue before publishing the message
        channel.queue_declare(queue="video", durable=True)

        # Publish the message to the video queue
        channel.basic_publish(
            exchange="",
            routing_key=os.environ.get("VIDEO_QUEUE"),
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE
            ),
        )
    except Exception as err:
        print(err)
        fs.delete(fid)
        return f"internal server error rabbitmq issue, {err}", 500
