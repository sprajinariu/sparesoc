// Copyright OpenSoC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * 32-bit GPIO with direction control and edge-triggered interrupts.
 *
 * Registers (offset from base):
 *   0x00  DIR        - Direction per pin (0=input, 1=output) R/W
 *   0x04  OUT        - Output value R/W
 *   0x08  IN         - Sampled input value R
 *   0x0C  IRQ_EN     - Interrupt enable per pin R/W
 *   0x10  IRQ_STATUS - Pending interrupts (write-1-to-clear) R/W1C
 */
module gpio (
  input  logic        clk_i,
  input  logic        rst_ni,

  // Bus interface
  input  logic        req_i,
  input  logic [31:0] addr_i,
  input  logic        we_i,
  input  logic [ 3:0] be_i,
  input  logic [31:0] wdata_i,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,

  // Interrupt
  output logic        irq_o,

  // GPIO pins
  input  logic [31:0] gpio_i,
  output logic [31:0] gpio_o,
  output logic [31:0] gpio_oe
);

  // ---------------------------------------------------------------------------
  // Register offsets
  // ---------------------------------------------------------------------------
  localparam logic [9:0] REG_DIR        = 10'h000;
  localparam logic [9:0] REG_OUT        = 10'h004;
  localparam logic [9:0] REG_IN         = 10'h008;
  localparam logic [9:0] REG_IRQ_EN     = 10'h00C;
  localparam logic [9:0] REG_IRQ_STATUS = 10'h010;

  // ---------------------------------------------------------------------------
  // Registers
  // ---------------------------------------------------------------------------
  logic [31:0] dir_q;
  logic [31:0] out_q;
  logic [31:0] irq_en_q;
  logic [31:0] irq_status_q;

  assign gpio_o  = out_q;
  assign gpio_oe = dir_q;

  // ---------------------------------------------------------------------------
  // Input synchronizer (2-FF)
  // ---------------------------------------------------------------------------
  logic [31:0] gpio_sync_q1, gpio_sync_q2, gpio_prev_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      gpio_sync_q1 <= '0;
      gpio_sync_q2 <= '0;
      gpio_prev_q  <= '0;
    end else begin
      gpio_sync_q1 <= gpio_i;
      gpio_sync_q2 <= gpio_sync_q1;
      gpio_prev_q  <= gpio_sync_q2;
    end
  end

  // ---------------------------------------------------------------------------
  // Rising-edge detection → IRQ status
  // ---------------------------------------------------------------------------
  logic [31:0] rising_edges;
  assign rising_edges = gpio_sync_q2 & ~gpio_prev_q;

  // ---------------------------------------------------------------------------
  // Bus read/write
  // ---------------------------------------------------------------------------
  logic [31:0] rdata_q;
  logic        rvalid_q;

  assign rvalid_o = rvalid_q;
  assign rdata_o  = rdata_q;

  // W1C mask: bits to clear in irq_status on a write
  logic [31:0] irq_w1c_mask;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid_q     <= 1'b0;
      rdata_q      <= '0;
      dir_q        <= '0;
      out_q        <= '0;
      irq_en_q     <= '0;
      irq_status_q <= '0;
      irq_w1c_mask <= '0;
    end else begin
      rvalid_q     <= 1'b0;
      irq_w1c_mask <= '0;

      // Set new edges (always, regardless of bus access)
      irq_status_q <= (irq_status_q | (rising_edges & irq_en_q)) & ~irq_w1c_mask;

      if (req_i) begin
        rvalid_q <= 1'b1;
        if (we_i) begin
          case (addr_i[9:0])
            REG_DIR: begin
              if (be_i[0]) dir_q[ 7: 0] <= wdata_i[ 7: 0];
              if (be_i[1]) dir_q[15: 8] <= wdata_i[15: 8];
              if (be_i[2]) dir_q[23:16] <= wdata_i[23:16];
              if (be_i[3]) dir_q[31:24] <= wdata_i[31:24];
            end
            REG_OUT: begin
              if (be_i[0]) out_q[ 7: 0] <= wdata_i[ 7: 0];
              if (be_i[1]) out_q[15: 8] <= wdata_i[15: 8];
              if (be_i[2]) out_q[23:16] <= wdata_i[23:16];
              if (be_i[3]) out_q[31:24] <= wdata_i[31:24];
            end
            REG_IRQ_EN: begin
              if (be_i[0]) irq_en_q[ 7: 0] <= wdata_i[ 7: 0];
              if (be_i[1]) irq_en_q[15: 8] <= wdata_i[15: 8];
              if (be_i[2]) irq_en_q[23:16] <= wdata_i[23:16];
              if (be_i[3]) irq_en_q[31:24] <= wdata_i[31:24];
            end
            REG_IRQ_STATUS: begin
              // Write-1-to-clear
              irq_w1c_mask <= wdata_i;
            end
            default: ;
          endcase
        end else begin
          case (addr_i[9:0])
            REG_DIR:        rdata_q <= dir_q;
            REG_OUT:        rdata_q <= out_q;
            REG_IN:         rdata_q <= gpio_sync_q2;
            REG_IRQ_EN:     rdata_q <= irq_en_q;
            REG_IRQ_STATUS: rdata_q <= irq_status_q;
            default:        rdata_q <= '0;
          endcase
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // Interrupt output
  // ---------------------------------------------------------------------------
  assign irq_o = |irq_status_q;

endmodule
