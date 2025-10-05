const std = @import("std");
const http = std.http;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    var client = http.Client{ .allocator = gpa.allocator() };
    defer client.deinit();

    // setup proxy from ENV, using arena allocator
    var proxy_arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer proxy_arena.deinit();
    try client.initDefaultProxies(proxy_arena.allocator());

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
