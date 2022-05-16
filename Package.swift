// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "GMSLibrary",
    products: [
        .library(name: "GMSLibrary", targets: [ "GMSLibrary" ])
    ],
    dependencies: [
        .package(url: "https://github.com/ckpwong/GFayeSwift.git", from: "0.5.10"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.8.0"),
        .package(url: "https://github.com/google/promises.git", from: "1.2.8")
    ],
    targets: [
        .target(
            name: "GMSLibrary",
            dependencies: [ "GFayeSwift", "Alamofire", "Promises" ],
            path: "GMSLibrary/Classes"
        )
    ]
)
