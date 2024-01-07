# localsend_rs

WIP: this repository is still WIP. 

A localsend protocol V2 implementation in flutter and rust for better performance.

## Compare

Performance compare between localsend original and localsend_rs

Test condition : 
 - router: TpLink AX3000M
 - sender: Xiaomi 13 ( localsend )
 - receiver: Windows PC ( localsend_rs / localsend )

| sender    | receiver     | network speed | disk speed |
| --------- | ------------ | ------------- | ---------- |
| localsend | localsend    | 144Mbps       | 26MB/s     |
| localsend | localsend_rs | 511Mbps       | 102M/s     |

## Roadmap

- [ ] Protocol V2
    - [x] Udp announce
    - [x] Register
    - [x] Prepare upload
    - [x] Upload
    - [ ] Cancel
    - [ ] Send
- [ ] User interface
    - [ ] device page
    - [ ] discover page
    - [ ] send page
    - [ ] setting page
- [ ] Platform
  - [x] Windows
  - [ ] Android

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
