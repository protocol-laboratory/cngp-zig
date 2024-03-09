const std = @import("std");
const net = std.net;
const CngpBody = @import("protocol.zig").CngpBody;
const CngpLogin = @import("protocol.zig").CngpLogin;
const CngpPdu = @import("protocol.zig").CngpPdu;
const CommandId = @import("constant.zig").CommandId;
const BoundAtomic = @import("bound_atomic.zig").BoundAtomic;

pub const CngpClient = struct {
    host: []const u8,
    port: u16,
    sequenceId: BoundAtomic,
    stream: ?std.net.Stream,

    pub fn init(host: []const u8, port: u16) CngpClient {
        return CngpClient{
            .host = host,
            .port = port,
            .sequenceId = BoundAtomic.new(1, 0x7FFFFFFF),
            .stream = null,
        };
    }

    pub fn connect(self: *CngpClient) !void {
        const peer = try net.Address.parseIp4(self.host, self.port);
        self.stream = try net.tcpConnectToAddress(peer);
    }

    pub fn login(self: *CngpClient, body: CngpLogin) !CngpPdu {
        const sequenceId = self.sequenceId.nextVal();
        const pdu = CngpPdu{
            .header = .{
                .total_length = 0, // Will be calculated in encode method
                .command_id = CommandId.Login,
                .command_status = 0,
                .sequence_id = sequenceId,
            },
            .body = CngpBody{ .Login = body },
        };
        const data = try pdu.encode();
        if (self.stream) |s| {
            const size = try s.write(data);
            if (size != data.len) {
                return error.WriteFailed;
            }

            var buffer: [4]u8 = undefined;
            const readLengthSize = try s.read(buffer[0..]);
            if (readLengthSize != 4) {
                return error.ReadFailed;
            }
            const remainLength = std.mem.readInt(u32, buffer[0..], .Big) - 4;

            var responseBuffer = try std.heap.page_allocator.alloc(u8, remainLength);
            defer std.heap.page_allocator.free(responseBuffer);

            var reader = s.reader();
            const readSize = try reader.read(responseBuffer[0..remainLength]);
            if (readSize != remainLength) {
                return error.ReadFailed;
            }

            const response = try CngpPdu.decode_login_resp(responseBuffer);
            return response;
        } else {
            return error.UnexpectedNull;
        }
    }

    pub fn close(self: *CngpClient) void {
        if (self.stream) |s| {
            s.close();
            self.stream = null;
        }
    }
};
