const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try std.fs.cwd().openFile("day4_input.txt", .{});
    const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);

    var map = try Map.init(allocator, contents);
    defer map.deinit();

    var gen: usize = 0;
    var total_sum: usize = 0;
    while (true) : (gen += 1) {
        var sum: usize = 0;
        var removable = std.ArrayList(Coordinate).empty;
        defer removable.deinit(allocator);
        for (0..map.height) |row| {
            for (0..map.width) |col| {
                const crd = Coordinate{ .row = @intCast(row), .col = @intCast(col) };
                const option = map.get(crd) orelse {
                    continue;
                };
                if (option != .roll) {
                    continue;
                }

                var occupied_neighbors: usize = 0;
                const neighbors = get_neighbors(crd);
                for (neighbors) |neighbor| {
                    const value = map.get(neighbor) orelse {
                        continue;
                    };
                    if (value == .roll) {
                        occupied_neighbors += 1;
                    }
                }
                if (occupied_neighbors < 4) {
                    sum += 1;
                    try removable.append(allocator, crd);
                }
            }
        }
        if (sum == 0) {
            break;
        }
        total_sum += sum;
        for (removable.items) |removable_crd| {
            map.remove(removable_crd);
        }
        std.debug.print("(Gen {}) {}\n", .{ gen, sum });
    }
    std.debug.print("Total: {}\n", .{total_sum});
}

const Coordinate = struct {
    row: i32,
    col: i32,
};

const Map = struct {
    const Self = @This();

    const Option = enum {
        empty,
        roll,
    };

    allocator: std.mem.Allocator,
    contents: []Option,
    height: usize,
    width: usize,

    pub fn init(allocator: std.mem.Allocator, contents: []const u8) !Self {
        var parsed_contents = std.ArrayList(Option).empty;

        var lines = std.mem.splitAny(u8, contents, "\n\r");
        var width: usize = 0;
        var height: usize = 0;
        while (lines.next()) |line| : (height += 1) {
            const stripped_line = std.mem.trim(u8, line, " \r\n\t");
            if (stripped_line.len == 0) {
                continue;
            }
            if (width == 0) {
                width = line.len;
            } else if (width != line.len) {
                @panic("Malformed input; width not consistent.");
            }

            for (line) |char| {
                switch (char) {
                    '.' => try parsed_contents.append(allocator, .empty),
                    '@' => try parsed_contents.append(allocator, .roll),
                    else => @panic("Malformed input. Unrecognized char."),
                }
            }
        }

        return .{
            .allocator = allocator,
            .contents = try parsed_contents.toOwnedSlice(allocator),
            .height = height,
            .width = width,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.contents);
    }

    pub fn get(self: *const Self, crd: Coordinate) ?Option {
        if (crd.row < 0 or crd.row >= self.height or crd.col < 0 or crd.col >= self.width) {
            return null;
        }
        const row: usize = @intCast(crd.row);
        const col: usize = @intCast(crd.col);
        return self.contents[col + row * self.width];
    }

    pub fn remove(self: *Self, crd: Coordinate) void {
        if (crd.row < 0 or crd.row >= self.height or crd.col < 0 or crd.col >= self.width) {
            return;
        }
        const row: usize = @intCast(crd.row);
        const col: usize = @intCast(crd.col);
        self.contents[col + row * self.width] = .empty;
    }
};

pub fn get_neighbors(crd: Coordinate) [8]Coordinate {
    return .{
        .{ .row = crd.row - 1, .col = crd.col - 1 },
        .{ .row = crd.row - 1, .col = crd.col },
        .{ .row = crd.row - 1, .col = crd.col + 1 },
        .{ .row = crd.row, .col = crd.col - 1 },
        .{ .row = crd.row, .col = crd.col + 1 },
        .{ .row = crd.row + 1, .col = crd.col - 1 },
        .{ .row = crd.row + 1, .col = crd.col },
        .{ .row = crd.row + 1, .col = crd.col + 1 },
    };
}
