const std = @import("std");
const http = std.http;
const http_fetch = @import("http_fetch");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    var client = http.Client{ .allocator = gpa.allocator() };
    defer client.deinit();

    var result_body = std.Io.Writer.Allocating.init(gpa.allocator());
    defer result_body.deinit();

    const response = try client.fetch(.{
        .method = http.Method.GET,
        .location = .{ .url = "http://httpbun.com/get" },
        .redirect_behavior = .unhandled,
        // standard headers
        .headers = .{
            .accept_encoding = .default,
            .connection = .default,
            .user_agent = .{ .override = "zig" },
        },
        // extra headers
        .extra_headers = &.{
            .{ .name = "accept", .value = "application/json" },
        },
        // privileged headers
        .privileged_headers = &.{},
        // request payload, can be null
        .payload = null,
        // if the server sends a body, it will be written here
        .response_writer = &result_body.writer,
    });

    if (response.status.class() == .success) {
        std.debug.print("{d} {?s}, response body: {s}", .{ response.status, response.status.phrase(), result_body.written() });
    } else {
        std.debug.print("Error: {d} {?s}", .{ response.status, response.status.phrase() });
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
