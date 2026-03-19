import threading
from contextlib import asynccontextmanager

import rclpy
from fastapi import FastAPI
from rclpy.node import Node
from std_msgs.msg import String
import uvicorn

ros_node: 'ApiPublisherNode | None' = None
spin_thread: threading.Thread | None = None


class ApiPublisherNode(Node):
    def __init__(self) -> None:
        super().__init__('api_publisher_node')
        self.publisher = self.create_publisher(String, '/demo', 10)
        self.get_logger().info('API publisher listo para publicar en /demo')

    def publish_text(self, text: str) -> None:
        msg = String()
        msg.data = text
        self.publisher.publish(msg)
        self.get_logger().info(f'Mensaje publicado desde API: {text}')


def start_ros() -> None:
    global ros_node, spin_thread

    if ros_node is not None:
        return

    rclpy.init(args=None)
    ros_node = ApiPublisherNode()
    spin_thread = threading.Thread(target=rclpy.spin, args=(ros_node,), daemon=True)
    spin_thread.start()


def stop_ros() -> None:
    global ros_node, spin_thread

    if ros_node is None:
        return

    ros_node.destroy_node()
    ros_node = None
    rclpy.shutdown()
    spin_thread = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    start_ros()
    try:
        yield
    finally:
        stop_ros()


app = FastAPI(title='ROS2 API Ultra Simple', lifespan=lifespan)


@app.get('/')
def root() -> dict:
    return {'message': 'API funcionando'}


@app.post('/send')
def send(msg: str) -> dict:
    if ros_node is None:
        raise RuntimeError('ROS 2 no esta inicializado')

    ros_node.publish_text(msg)
    return {'status': 'sent', 'msg': msg}


if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8001, reload=False)
