/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`include "../src/pwm_peripheral.v"

// Change the module name!
module tt_um_uwasic_onboarding_sanjay_jayaram(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
  );

  // Add this inside the module block
  assign uio_oe = 8'hFF; // Set all IOs to output
  
  // Create wires to refer to the values of the registers
  wire [7:0] en_reg_out_7_0;
  wire [7:0] en_reg_out_15_8;
  wire [7:0] en_reg_pwm_7_0;
  wire [7:0] en_reg_pwm_15_8;
  wire [7:0] pwm_duty_cycle;

  wire SCLK;
  wire nCS;
  wire COPI;

  reg [3:0] current_point = 0;
  reg rw = 0;
  reg [6:0] address = 0;
  reg [6:0] data = 0; //only need 7 bits to store it, as the last bit will be read when it's given

  reg [4:0][7:0] memory = 0;

  // Instantiate the PWM module
  pwm_peripheral pwm_peripheral_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg_out_7_0(en_reg_out_7_0),
    .en_reg_out_15_8(en_reg_out_15_8),
    .en_reg_pwm_7_0(en_reg_pwm_7_0),
    .en_reg_pwm_15_8(en_reg_pwm_15_8),
    .pwm_duty_cycle(pwm_duty_cycle),
    .out({uio_out, uo_out})
  );

  assign SCLK = ui_in[0];
  assign COPI = ui_in[1];
  assign nCS  = ui_in[2];

  assign en_reg_out_7_0 = memory[0];
  assign en_reg_out_15_8 = memory[1];
  assign en_reg_pwm_7_0 = memory[2];
  assign en_reg_pwm_15_8 = memory[3];
  assign pwm_duty_cycle = memory[4];

  //handle the input stuff
  always @(posedge SCLK) begin
    if(!nCS) begin
      if(current_point==0) begin //read/write
        rw <= COPI;
      end else if (current_point < 8) begin //address
        address[7 - current_point] <= COPI;
      end else if (current_point < 15) begin //data (most of it)
        data[14 - current_point] <= COPI;
      end else if (current_point == 15) begin //rest of the data and executing the transaction
        if (rw) begin //write
          memory[address] = {data,COPI};
        end
      end
      current_point <= current_point + 1;
    end else begin
      current_point <= 0;
      rw <= 0;
      address <= 0;
      data <= 0;
    end
  end

  //now we handle the outputs
  // Add uio_in and ui_in[7:3] to the list of unused signals:
  wire _unused = &{ena, ui_in[7:3], uio_in, 1'b0};

endmodule
