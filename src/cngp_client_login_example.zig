const std = @import("std");
const CngpClient = @import("cngp_client.zig").CngpClient;
const CngpLogin = @import("protocol.zig").CngpLogin;

pub fn main() !void {
    const host = "127.0.0.1";
    const port: u16 = 9890;

    var client = CngpClient.init(host, port);
    defer client.close();

    const clientId = "1234567890";
    const authenticatorClient = "1234567890123456";
    const loginMode: u8 = 1;
    const timeStamp: i32 = 123456789;
    const version: u8 = 1;

    const loginBody = CngpLogin{
        .clientId = clientId,
        .authenticatorClient = authenticatorClient,
        .loginMode = loginMode,
        .timeStamp = timeStamp,
        .version = version,
    };

    try client.connect();
    const response = try client.login(loginBody);
    try std.io.getStdOut().writer().print("Login response: {}\n", .{response});
}
