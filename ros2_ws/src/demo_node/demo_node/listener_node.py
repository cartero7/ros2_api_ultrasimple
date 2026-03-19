import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class ListenerNode(Node):
    def __init__(self) -> None:
        super().__init__('listener_node')
        self.create_subscription(String, '/demo', self.on_message, 10)
        self.get_logger().info('ListenerNode escuchando en /demo')

    def on_message(self, msg: String) -> None:
        self.get_logger().info(f'Recibido por ROS2: {msg.data}')


def main() -> None:
    rclpy.init()
    node = ListenerNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
