module top(
    input clk,
    output [15:0] led
);
    reg [26:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // Use the top bits of the counter to blink LEDs
    assign led = counter[26:11];
endmodule