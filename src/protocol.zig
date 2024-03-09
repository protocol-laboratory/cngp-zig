const std = @import("std");
const io = std.io;
const CommandId = @import("constant.zig").CommandId;

pub const CngpLogin = struct {
    clientId: []const u8,
    authenticatorClient: []const u8,
    loginMode: u8,
    timeStamp: i32,
    version: u8,

    pub fn length(self: *const CngpLogin) usize {
        return self.clientId.len + self.authenticatorClient.len + 1 + 4 + 1;
    }

    pub fn encode(self: *const CngpLogin, writer: anytype) !void {
        try writer.writeAll(self.clientId);
        try writer.writeAll(self.authenticatorClient);
        try writer.writeByte(self.loginMode);
        try writer.writeIntBig(i32, self.timeStamp);
        try writer.writeByte(self.version);
    }
};

pub const CngpLoginResp = struct {
    authenticatorServer: []const u8,
    version: u8,

    pub fn decode(buffer: []u8) !CngpLoginResp {
        var stream = std.io.fixedBufferStream(buffer);
        var reader = stream.reader();
        var authenticatorServerBuffer: [16]u8 = undefined;
        var fixedSize = try reader.read(&authenticatorServerBuffer);
        if (fixedSize != 16) {
            return error.InvalidLength;
        }
        const version = try reader.readByte();
        return CngpLoginResp{
            .authenticatorServer = authenticatorServerBuffer[0..],
            .version = version,
        };
    }
};

pub const CngpHeader = struct {
    total_length: i32,
    command_id: CommandId,
    command_status: i32,
    sequence_id: i32,
};

pub const CngpBody = union(enum) {
    Login: CngpLogin,
    LoginResp: CngpLoginResp,
};

pub const CngpPdu = struct {
    header: CngpHeader,
    body: CngpBody,

    pub fn length(self: *const CngpPdu) usize {
        return 16 + switch (self.body) {
            .Login => |login| login.length(),
            else => 0,
        };
    }

    pub fn encode(self: *const CngpPdu) ![]u8 {
        const len = self.length();
        var buffer = try std.heap.page_allocator.alloc(u8, len);
        var stream = std.io.fixedBufferStream(buffer);
        var writer = stream.writer();
        try writer.writeInt(i32, @as(i32, @intCast(len)), .Big);
        try writer.writeInt(u32, @intFromEnum(self.header.command_id), .Big);
        try writer.writeInt(i32, self.header.command_status, .Big);
        try writer.writeInt(i32, self.header.sequence_id, .Big);
        switch (self.body) {
            .Login => |login| try login.encode(writer),
            else => unreachable,
        }
        return buffer;
    }

    pub fn decode_login_resp(buffer: []u8) !CngpPdu {
        var header: CngpHeader = undefined;
        header.total_length = 0;
        header.command_id = CommandId.LoginResp;
        header.command_status = std.mem.readIntLittle(i32, buffer[8..12]);
        header.sequence_id = std.mem.readIntLittle(i32, buffer[12..16]);

        const body = try CngpLoginResp.decode(buffer[12..]);
        return CngpPdu{
            .header = header,
            .body = CngpBody{ .LoginResp = body },
        };
    }
};
