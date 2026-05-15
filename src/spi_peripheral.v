`default_nettype none

module spi_peripheral (
    input wire clk, 
    input wire rst_n,
    input wire sclk,
    input wire copi, 
    input wire ncs,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

reg sclk_sync1, sclk_sync2, sclk_sync3;
reg copi_sync1, copi_sync2;
reg ncs_sync1, ncs_sync2;

always @(posedge clk or negedge rst_n) begin
    if (rst_n==0) begin
        sclk_sync1 <=0;
        sclk_sync2 <=0;
        sclk_sync3 <=0;
        copi_sync1 <=0;
        copi_sync2 <=0;
        ncs_sync1 <=1;
        ncs_sync2 <=1;
    end else begin 
        sclk_sync1 <=sclk;
        sclk_sync2 <= sclk_sync1;
        sclk_sync3 <= sclk_sync2;
        copi_sync1 <= copi;
        copi_sync2 <= copi_sync1;
        ncs_sync1  <= ncs;
        ncs_sync2  <= ncs_sync1;
    end
end

wire sclk_rising;
wire ncs_rising;

assign sclk_rising = (sclk_sync2 == 1) && (sclk_sync3 == 0);
assign ncs_rising = (ncs_sync1 == 1) && (ncs_sync2 == 0);

reg [4:0] bit_count;
reg [15:0] shift_reg;
reg transaction_ready;

always @(posedge clk or negedge rst_n) begin 
    if (rst_n == 0) begin
        bit_count <= 0;
        shift_reg <= 0;
        transaction_ready <= 0;
    end else begin
        transaction_ready <= 0;
        if (ncs_sync2 == 1) begin
            bit_count <= 0;
        end else if (sclk_rising) begin 
            shift_reg <= {shift_reg[14:0], copi_sync2};
            bit_count <= bit_count + 1;
        end

        if (ncs_rising && bit_count == 16) begin
            transaction_ready <= 1;
        end
    end
end

localparam max_address = 7'h04;

wire rw_bit;
wire [6:0] address;
wire [7:0] data;

assign rw_bit = shift_reg[15];
assign address = shift_reg[14:8];
assign data = shift_reg[7:0];

always @(posedge clk or negedge rst_n) begin 
    if (rst_n == 0) begin 
        en_reg_out_7_0 <= 8'h00;
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0 <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle <= 8'h00;
    end else if (transaction_ready && (rw_bit == 1) && (address <= max_address)) begin 
        case (address)
        7'h00: en_reg_out_7_0 <= data;
        7'h01: en_reg_out_15_8 <= data;
        7'h02: en_reg_pwm_7_0 <= data;
        7'h03: en_reg_pwm_15_8 <= data;
        7'h04: pwm_duty_cycle <= data;
        endcase
    end
end
endmodule 