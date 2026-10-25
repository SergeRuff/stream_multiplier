module stream_multiplier
# (
    parameter width = 8,
    parameter depth = 10
)
(
                            input                      CLK,
                            input                      LOAD1,
                            input                      LOAD2,
                            input                      RESET,
                            input        [0:width - 1] DIN,

                            output logic [width - 1:0] DOUT,
                            output logic               OE
                        );

    localparam counter_width = $clog2(depth + 1);

    logic buffer1_pop;
    logic buffer1_rst;
    logic buffer1_push;
    logic buffer1_full_flag;
    logic buffer1_almost_full_flag;
    logic buffer1_empty_flag;
    logic buffer1_almost_empty_flag;
    logic buffer1_error_flag;
    logic [counter_width - 1: 0] buffer1_counter;
    logic [width - 1:0] buffer1_data_out;

    logic buffer2_pop;
    logic buffer2_rst;
    logic buffer2_push;
    logic buffer2_full_flag;
    logic buffer2_almost_full_flag;
    logic buffer2_empty_flag;
    logic buffer2_almost_empty_flag;
    logic buffer2_error_flag;
    logic [counter_width - 1: 0] buffer2_counter;
    logic [width - 1:0] buffer2_data_out;

    logic buffers_reload_flag;
    logic illegal_state_flag;
    logic err_reg;
    logic err;

    typedef enum logic [2:0]    {
        ST_IDLE,
        ST_LOAD1,
        ST_LOAD2,
        ST_UPLOAD_RESULT,
        ST_ERROR
    }   states_e;

    states_e current_state, next_state;

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

    always_comb begin   :   illegal_state_checker
        illegal_state_flag = LOAD1 & LOAD2;
    end :   illegal_state_checker

    always_ff @(posedge CLK) begin  :   error_flag_registrator
        if (RESET)  err_reg <= '0;
        else        err_reg <= err;
    end :   error_flag_registrator

    always_comb begin   :   state_change_logic
        next_state = current_state;

        case (current_state)
            ST_IDLE:            if     (err)                                                     next_state = ST_ERROR;
                                else if(LOAD1 & !illegal_state_flag)                             next_state = ST_LOAD1;
            ST_LOAD1:           if     (err)                                                     next_state = ST_ERROR;
                                else if(LOAD2 & !illegal_state_flag)                             next_state = ST_LOAD2;
            ST_LOAD2:           if     (err)                                                     next_state = ST_ERROR;
                                else if(!LOAD2)                                                  next_state = ST_UPLOAD_RESULT; 
            ST_UPLOAD_RESULT:   if     (err)                                                     next_state = ST_ERROR;
                                else if(buffer1_almost_empty_flag & buffer2_almost_empty_flag)   next_state = ST_IDLE;
            ST_ERROR:           if     (!err & !LOAD1 & !LOAD2)                                  next_state = ST_IDLE;
            default:                                                                             next_state = ST_IDLE;
        endcase
    end :   state_change_logic

    always_ff @(posedge CLK) begin  :   state_registrate
        if(RESET) current_state <= ST_IDLE;
        else      current_state <= next_state;
    end :   state_registrate

    always_comb begin   :   buffers_control_logic
        buffer1_pop         = 'x;
        buffer1_rst         = 'x;
        buffer1_push        = 'x;
        buffer2_pop         = 'x;
        buffer2_rst         = 'x;
        buffer2_push        = 'x;
        buffers_reload_flag = 'x;

        if ((current_state == ST_UPLOAD_RESULT)&(next_state == ST_IDLE)) buffers_reload_flag = 1'b1;

        case (current_state)
            ST_IDLE:          begin    {buffer1_pop, buffer1_rst, buffer1_push} = {1'b0, RESET, (LOAD1 & !illegal_state_flag)};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = 3'b010;                                       end
            ST_LOAD1:         begin    {buffer1_pop, buffer1_rst, buffer1_push} = {2'b00, (LOAD1 & !illegal_state_flag)};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = '0;                                           end
            ST_LOAD2:         begin    {buffer1_pop, buffer1_rst, buffer1_push} = '0;
                                       {buffer2_pop, buffer2_rst, buffer2_push} = {2'b00, (LOAD2 & !illegal_state_flag)};       end
            ST_UPLOAD_RESULT: begin    {buffer1_pop, buffer1_rst, buffer1_push} = {1'b1, buffers_reload_flag, 1'b0};
                                       {buffer2_pop, buffer2_rst, buffer2_push} = {1'b1, buffers_reload_flag, 1'b0};            end
            ST_ERROR:         begin    {buffer1_pop, buffer1_rst, buffer1_push} = 3'b010;
                                       {buffer2_pop, buffer2_rst, buffer2_push} = 3'b010;                                       end
            default:          begin    {buffer1_pop, buffer1_rst, buffer1_push} = 3'b010;
                                       {buffer2_pop, buffer2_rst, buffer2_push} = 3'b010;                                       end
        endcase
    end :   buffers_control_logic

    always_ff @(posedge CLK) begin  :   data_output_logic
        if (RESET)  DOUT <= '0;
        else case (current_state)
            ST_IDLE:          DOUT <= '0;
            ST_LOAD1:         DOUT <= '0;
            ST_LOAD2:         DOUT <= '0;
            ST_UPLOAD_RESULT: DOUT <= buffer1_data_out * buffer2_data_out;
            ST_ERROR:         DOUT <= 'x;
            default:          DOUT <= 'x;
        endcase
    end :   data_output_logic

    always_ff @(posedge CLK) begin   :   status_flags_logic
        if (RESET)  OE <= '0;
        else        OE <= (current_state == ST_UPLOAD_RESULT);
    end :   status_flags_logic

    always_comb begin   :   error_flag_logic
        err = buffer1_error_flag | buffer2_error_flag;
    end :   error_flag_logic

endmodule
