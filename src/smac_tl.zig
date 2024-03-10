const std = @import("std");
const stdout = std.io.getStdOut().writer();
const net = std.net;

pub fn main() !void {
    var biglist = std.ArrayList(u8).init(std.heap.page_allocator);
    defer biglist.deinit();

    var index: u32 = 0;
    while (index < 1000001) : (index += 1) {
        if (index % 10 == 7 or index % 7 == 0) {
            try biglist.writer().print("SMAC\n|", .{});
        } else {
            try biglist.writer().print("{d}\n|", .{index});
        }
    }

    var server = net.StreamServer.init(.{});
    server.reuse_address = true;
    defer server.deinit();

    try server.listen(net.Address.parseIp("0.0.0.0", 7979) catch unreachable);
    try stdout.print("Listening on {}\n", .{server.listen_address});

    while (true) {
        var conn = try server.accept();
        _ = try std.Thread.spawn(.{}, print_list, .{ &biglist, conn });
    }
}

fn print_list(list: *std.ArrayList(u8), conn: net.StreamServer.Connection) !void {
    var iter = std.mem.split(u8, list.items, "|");
    while (iter.next()) |item| {
        _ = try conn.stream.write(item);
    }
    conn.stream.close();
}
