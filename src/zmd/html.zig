const tokens = @import("tokens.zig");

/// Default fragments. Pass this to `Zmd.toHtml` or provide your own.
pub const DefaultFragments = struct {
    pub const root = .{ "<!DOCTYPE html><html><body><div>", "</div></body></html>\n" };
    pub const h1 = .{ "<h1>", "</h1>\n" };
    pub const h2 = .{ "<h2>", "</h2>\n" };
    pub const h3 = .{ "<h3>", "</h3>\n" };
    pub const h4 = .{ "<h4>", "</h4>\n" };
    pub const h5 = .{ "<h5>", "</h5>\n" };
    pub const h6 = .{ "<h6>", "</h6>\n" };
    pub const text = .{ "", "\n" };
    pub const bold = .{ "<b>", "</b>\n" };
    pub const italic = .{ "<i>", "</i>\n" };
    pub const code = .{ "<span style=\"font-family: Monospace\">", "</span>\n" };
    pub const block = .{ "<pre style=\"font-family: Monospace\">", "</pre>\n" };
    pub const paragraph = .{ "<p>", "</p>" };
};
