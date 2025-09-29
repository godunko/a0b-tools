# ESP32S3 Runtime Example

## How to build

1. Checkout and build GCC toolchain plugins

```
    git clone https://github.com/godunko/xtensa-dynconfig.git
    alr -C xtensa-dynconfig build
```

2. Checkout and build `A0B-Tools`

```
    git clone https://github.com/godunko/a0b-tools.git
    alr -C a0b-tools build
```

3. Checkout `bb-runtimes`

```
    git clone git@github.com:alire-project/bb-runtimes.git bb-runtimes-15 --branch gnat-fsf-15
```

3. Enter example directory and build demo

```
    cd a0b-tools/example/esp32s3
    alr build
```

You can find generated runtime in `runtime` directory.
Feel free to modify `runtime.json` to add more runtime features!

Application is build as static library, and exports two symbols:
 - `light_esp32_demoinit`
 - `_ada_main`

First symbol do elaboration of the application, and second run application's main subprogram.
