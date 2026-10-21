module stream_multiplier(
                            input        CLK,
                            input        LOAD1,
                            input        LOAD2,
                            input        RESET,
                            input  [0:7] DIN,

                            output [7:0] DOUT,
                            output       OE
                        );

    logic buffer1_full_flag;
    logic buffer1_empty_flag;
    logic buffer1_counter;

    logic buffer2_full_flag;
    logic buffer2_empty_flag;
    logic buffer2_counter;

    logic err;

    typedef enum logic [2:0]    {
        ST_IDLE,
        ST_LOAD1,
        ST_LOAD2,
        ST_UPLOAD_RESULT,
        ST_ERROR
    }   states_e;

    states_e current_state, next_state;



endmodule