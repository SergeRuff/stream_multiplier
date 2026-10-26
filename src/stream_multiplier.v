module stream_multiplier
# (
    parameter width = 8,
    parameter depth = 128
)
(
                            input                    CLK,
                            input                    LOAD1,
                            input                    LOAD2,
                            input                    RESET,
                            input      [0:width - 1] DIN,

                            output reg [width - 1:0] DOUT,
                            output reg               OE
                        );

    localparam counter_width = $clog2(depth + 1);

    reg buffer1_pop;
    reg buffer1_rst;
    reg buffer1_push;
    wire buffer1_full_flag;
    wire buffer1_almost_full_flag;
    wire buffer1_empty_flag;
    wire buffer1_almost_empty_flag;
    wire buffer1_error_flag;
    wire [counter_width - 1: 0] buffer1_counter;
    wire [width - 1:0] buffer1_data_out;

    reg buffer2_pop;
    reg buffer2_rst;
    reg buffer2_push;
    wire buffer2_full_flag;
    wire buffer2_almost_full_flag;
    wire buffer2_empty_flag;
    wire buffer2_almost_empty_flag;
    wire buffer2_error_flag;
    wire [counter_width - 1: 0] buffer2_counter;
    wire [width - 1:0] buffer2_data_out;

    reg buffers_reload_flag;
    wire illegal_state_flag;
    wire err;

    localparam [2:0] ST_IDLE          = 3'd0,
                     ST_LOAD1         = 3'd1,
                     ST_LOAD2         = 3'd2,
                     ST_UPLOAD_RESULT = 3'd3,
                     ST_ERROR         = 3'd4;

    reg [2:0] current_state, next_state;

    oneshot_buffer #(
        .width(width),
        .depth(depth),
        .REVERSE_BUFFER_MODE(1'b0)
    ) buffer1 (
        .clk(CLK),
        .rst(buffer1_rst),
        .push(buffer1_push),
        .pop(buffer1_pop),
        .write_data(DIN),
        .read_data(buffer1_data_out),
        .cnt(buffer1_counter),
        .empty(buffer1_empty_flag),
        .almost_empty(buffer1_almost_empty_flag),
        .full(buffer1_full_flag),
        .almost_full(buffer1_almost_full_flag),
        .err(buffer1_error_flag)
    );

    oneshot_buffer #(
            .width(width),
            .depth(depth),
            .REVERSE_BUFFER_MODE(1'b1)
    ) buffer2 (
        .clk(CLK),
        .rst(buffer2_rst),
        .push(buffer2_push),
        .pop(buffer2_pop),
        .write_data(DIN),
        .read_data(buffer2_data_out),
        .cnt(buffer2_counter),
        .empty(buffer2_empty_flag),
        .almost_empty(buffer2_almost_empty_flag),
        .full(buffer2_full_flag),
        .almost_full(buffer2_almost_full_flag),
        .err(buffer2_error_flag)
    );

    assign illegal_state_flag = LOAD1 & LOAD2;
    assign err = buffer1_error_flag | buffer2_error_flag;

    always @(*) begin   :   state_change_logic
        next_state = current_state;

        case (current_state)
            ST_IDLE:            if     (err)                                                     next_state = ST_ERROR;
                                else if(LOAD1 & !illegal_state_flag)                             next_state = ST_LOAD1;
            ST_LOAD1:           if     (err)                                                     next_state = ST_ERROR;
                                else if(LOAD2 & !illegal_state_flag)                             next_state = ST_LOAD2;
            ST_LOAD2:           if     (err)                                                     next_state = ST_ERROR;
                                else if(!LOAD1 & !LOAD2)                                         next_state = ST_UPLOAD_RESULT; 
            ST_UPLOAD_RESULT:   if     (err)                                                     next_state = ST_ERROR;
                                else if(buffer1_almost_empty_flag & buffer2_almost_empty_flag)   next_state = ST_IDLE;
            ST_ERROR:           if     (!err & !LOAD1 & !LOAD2)                                  next_state = ST_IDLE;
            default:                                                                             next_state = ST_IDLE;
        endcase
    end

    always @(posedge CLK) begin  :   state_registrate
        if(RESET) current_state <= ST_IDLE;
        else      current_state <= next_state;
    end

    always @(*) begin   :   buffers_control_logic
        buffer1_pop         = 1'bx;
        buffer1_rst         = 1'bx;
        buffer1_push        = 1'bx;
        buffer2_pop         = 1'bx;
        buffer2_rst         = 1'bx;
        buffer2_push        = 1'bx;
        buffers_reload_flag = ((current_state==ST_UPLOAD_RESULT)&(next_state==ST_IDLE));

        case (current_state)
            ST_IDLE:          begin    {buffer1_pop, buffer1_rst, buffer1_push} = {1'b0, RESET, (LOAD1 & !illegal_state_flag)};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = {1'b0, 1'b1, 1'b0};                           end
            ST_LOAD1:         begin    {buffer1_pop, buffer1_rst, buffer1_push} = {1'b0, RESET, (LOAD1 & !illegal_state_flag)};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = {1'b0, RESET, (LOAD2 & !illegal_state_flag)}; end
            ST_LOAD2:         begin    {buffer1_pop, buffer1_rst, buffer1_push} = {(!LOAD1 & !LOAD2), RESET, 1'b0};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = {(!LOAD1 & !LOAD2), RESET, (LOAD2 & !illegal_state_flag)}; end
            ST_UPLOAD_RESULT: begin    {buffer1_pop, buffer1_rst, buffer1_push} = {1'b1, buffers_reload_flag | RESET, 1'b0};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = {1'b1, buffers_reload_flag | RESET, 1'b0};    end
            ST_ERROR:         begin    {buffer1_pop, buffer1_rst, buffer1_push} = 3'b010;
                                       {buffer2_pop, buffer2_rst, buffer2_push} = 3'b010;                                       end
            default:          begin    {buffer1_pop, buffer1_rst, buffer1_push} = 3'b010;
                                       {buffer2_pop, buffer2_rst, buffer2_push} = 3'b010;                                       end
        endcase
    end

    always @(posedge CLK) begin  :   data_output_logic
        if (RESET)  DOUT <= 0;
        else case (current_state)
            ST_IDLE:          DOUT <= 0;
            ST_LOAD1:         DOUT <= 0;
            ST_LOAD2:         DOUT <= (next_state == ST_UPLOAD_RESULT)? buffer1_data_out * buffer2_data_out : 0;
            ST_UPLOAD_RESULT: DOUT <= buffer1_data_out * buffer2_data_out;
            ST_ERROR:         DOUT <= {width{1'bx}};
            default:          DOUT <= {width{1'bx}};
        endcase
    end

    always @(posedge CLK) begin   :   status_flags_logic
        if (RESET)  OE <= 1'b0;
        else        OE <= (current_state == ST_UPLOAD_RESULT)|
                          (next_state    == ST_UPLOAD_RESULT);
    end

endmodule
