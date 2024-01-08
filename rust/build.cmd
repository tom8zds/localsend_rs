cd rust
cargo ndk -o ../android/app/src/main/jniLibs -t arm64-v8a -t armeabi-v7a --manifest-path ./Cargo.toml build --release