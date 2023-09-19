# ROS2WASM Builder

This action cross-compiles a ROS 2 package to WebAssembly and uploads the built files as artifacts.

## Usage

```yaml
- steps:
    uses: actions/ros2wasm-builder@v1
    with:
        package: 'the_target_package'
        ros_distro: 'humble'
        debug_mode: false
```
