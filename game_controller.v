module game_controller(
	//Clock and reset
	clk,
	reset_n,
	//Frame synchronization input
	iVS,
	//Keyboard input
	iKEY,
	change,
	//Background selection
	oBkg_sel,
	//Object ram interface
	oObjRam_addr,
	oObjRam_data,
	oObjRam_we
);
/* PORT declarations
 */
//Clock and reset
input          clk;
input          reset_n;
//Frame synchronization input
input          iVS;
//Keyboard input
input  [ 7: 0] iKEY;
input 			change;
//Background selection
output reg [ 1: 0] oBkg_sel;
//Object ram interface
output reg [ 2: 0] oObjRam_addr;
output reg [12: 0] oObjRam_data;
output reg         oObjRam_we;

/* Organization of 13-bit object data: 
 * 12     | 11 .. 9 | 8 .. 4 | 3 .. 0 |
 * ON/OFF   TILE NO.  X COOR   Y COOR
 */

/* Parameters definition
 */

/* REG/WIRE declarations
 */
reg  [ 7: 0] clkCount;      //Clock counter for system timing

reg          lastVS;        //Last VS signal
wire         frameSyn;      //Frame synchronize flag

reg  [ 7: 0] keyVal;        //Keyboard value
reg  [ 5: 0] keyLPCnt;
reg  [ 7: 0] lastSW;

reg  [ 4: 0] xPos_man;  //X position of bomb man (1 - 17)
reg  [ 3: 0] yPos_man;  //Y position of bomb man (1 - 13)

reg  [ 4: 0] xPos_man2; //X position of bomb man2 (1 - 17)
reg  [ 3: 0] yPos_man2; //Y position of bomb man2 (1 - 13)

reg  [ 4: 0] xPos_sprite;   //X position of sprite (1 - 17)
reg  [ 3: 0] yPos_sprite;   //Y position of sprite (1 - 13)
reg  [ 2: 0] dir_sprite;    //Moving direction of sprite (0: L, 1: R, 2: U, 3: D)
reg  [ 4: 0] mClk_sprite;   //Sprite moving clock divider

reg  [ 4: 0] xPos_sprite2;   //X position of sprite (1 - 17)
reg  [ 3: 0] yPos_sprite2;   //Y position of sprite (1 - 13)
reg  [ 2: 0] dir_sprite2;    //Moving direction of sprite (0: L, 1: R, 2: U, 3: D)
reg  [ 4: 0] mClk_sprite2;   //Sprite moving clock divider

reg  [ 3: 0] fsm_objWR;     //State machine of object ram writing

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) 
	oBkg_sel=0; //play state
	else begin 
	if(oBkg_sel==0 && (Collision(xPos_man2,yPos_man2,xPos_sprite,yPos_sprite) 
		|| Collision(xPos_man2,yPos_man2,xPos_sprite2,yPos_sprite2)))
		oBkg_sel=1; //if man2 collides a sprite, man win
	if(oBkg_sel==0 && (Collision(xPos_man,yPos_man,xPos_sprite2,yPos_sprite2) 
		||Collision(xPos_man,yPos_man,xPos_sprite,yPos_sprite))) 
		oBkg_sel=2; //if man1 collides a sprite, man2 win
	end
end

//parameter of sprite
reg  [4: 0] x_diff;
reg  [3: 0] y_diff;
reg  [1: 0] dir_temp;
//parameter of sprite2
reg  [4: 0] x_diff2;
reg  [3: 0] y_diff2;
reg  [1: 0] dir_temp2;

/* LOGIC Descriptions
 */
//Frame synchronization
assign frameSyn = (lastVS && (~iVS));
always @(posedge clk) lastVS <= iVS;

//System timing
always @(posedge clk or negedge reset_n)
	if(!reset_n) clkCount <= 0;
	else if(frameSyn) clkCount <= 0;
	else if(clkCount != 8'hFF) clkCount <= clkCount + 1;
	
//Keyboard read-in
always @( posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		lastSW <= 0;
		keyVal <= 0;
	end
	else if(clkCount == 8'd0) begin
		lastSW <= ~iKEY;
		keyVal <= ~iKEY & (lastSW ^ ~iKEY); //if current keyboard input is different from last keyboard input,read in key value
	end

end
	
//Track judgement of man
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		xPos_man <= 1;
		yPos_man <= 1;    
	end
	else if(clkCount == 8'd1) begin

			case(keyVal[3: 0])
			4'b1000: begin //UP
				if(!get_background_up(xPos_man, yPos_man) && 
					!(xPos_man == xPos_man2 && yPos_man - 1 == yPos_man2))
					yPos_man <= yPos_man - 1;
			end
			4'b0100: begin //DOWN
				if(!get_background_down(xPos_man, yPos_man) &&
					!(xPos_man == xPos_man2 && yPos_man + 1 == yPos_man2))
					yPos_man <= yPos_man + 1;
			end
			4'b0010: begin //LEFT
				if(!get_background_left(xPos_man, yPos_man) &&
					!(xPos_man - 1 == xPos_man2 && yPos_man == yPos_man2))
					xPos_man <= xPos_man - 1;
			end
			4'b0001: begin //RIGHT
				if(!get_background_right(xPos_man, yPos_man) &&
					!(xPos_man + 1 == xPos_man2 && yPos_man == yPos_man2))
					xPos_man <= xPos_man + 1;
			end
			endcase
		
	end
end

//Track judgement of man 2
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		xPos_man2 <= 17;
		yPos_man2 <= 13;
	end
	else if(clkCount == 8'd1) begin

			case(keyVal[7: 4])
			4'b1000: begin //UP
				if(!get_background_up(xPos_man2, yPos_man2 ) &&
					!(xPos_man2 == xPos_man && yPos_man2 - 1 == yPos_man))
					yPos_man2 <= yPos_man2 - 1;
			end
			4'b0100: begin //DOWN
				if(!get_background_down(xPos_man2, yPos_man2 ) &&
					!(xPos_man2 == xPos_man && yPos_man2 + 1 == yPos_man))
					yPos_man2 <= yPos_man2 + 1;
			end
			4'b0010: begin //LEFT
				if(!get_background_left(xPos_man2 , yPos_man2) &&
					!(xPos_man2 - 1 == xPos_man && yPos_man2 == yPos_man))
					xPos_man2 <= xPos_man2 - 1;
			end
			4'b0001: begin //RIGHT
				if(!get_background_right(xPos_man2 , yPos_man2) &&
					!(xPos_man2 + 1 == xPos_man && yPos_man2 == yPos_man))
					xPos_man2 <= xPos_man2 + 1;
			end
			endcase
		
	end
end

//Track judgement of sprite
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		xPos_sprite <= 11;
		yPos_sprite <= 11;
		mClk_sprite <= 0;
	end
	else if(clkCount == 8'd1) begin
		mClk_sprite <= mClk_sprite + 1;
		if(mClk_sprite == 0) begin
				if(xPos_sprite < xPos_man) begin
					dir_temp[0] = 1;  //right
					x_diff = xPos_man - xPos_sprite; 
				end
				else begin
					dir_temp[0] = 0; //left
					x_diff = xPos_sprite - xPos_man;
				end
				if(yPos_sprite < yPos_man) begin
					dir_temp[1] = 1; //down
					y_diff = yPos_man - yPos_sprite;
				end
				else begin
					dir_temp[1] = 0; //up
					y_diff = yPos_sprite - yPos_man;
				end
         //find a path
			if(x_diff > y_diff && dir_temp[0] == 0) //no block on left
				if(!get_background_left(xPos_sprite,yPos_sprite))
					dir_sprite = 3'd0;
				else	//block on left
					begin
					if(dir_temp[1] == 0) //up
							if(!get_background_up(xPos_sprite,yPos_sprite))
								dir_sprite = 3'd2;
							else //block on left&up
								dir_sprite = 3'd4; //left&up at the same time 
					else
							if(!get_background_down(xPos_sprite,yPos_sprite)) //down
								dir_sprite = 3'd3; 
							else
								dir_sprite = 3'd5; //left&down at the same time
					end
			else if(x_diff > y_diff && dir_temp[0] == 1) //no block on right
				if(!get_background_right(xPos_sprite,yPos_sprite))
					dir_sprite = 3'd1;
				else	//block on right
				begin
					if(dir_temp[1] == 0) //up
							if(!get_background_up(xPos_sprite,yPos_sprite))
								dir_sprite = 3'd2;
							else
								dir_sprite = 3'd6; //right&up at the same time
					else						//down
							if(!get_background_down(xPos_sprite,yPos_sprite))
								dir_sprite = 3'd3;
							else
								dir_sprite = 3'd7;//right&down at the same time
				end
			else if(x_diff <= y_diff && dir_temp[1] == 0)//no block on up
				if(!get_background_up(xPos_sprite,yPos_sprite))
					dir_sprite = 3'd2;
				else//up
				begin
					if(dir_temp[0] == 0)//left
						if(!get_background_left(xPos_sprite,yPos_sprite))
							dir_sprite = 3'd0;
						else
							dir_sprite = 3'd4;//left&up at the same time
					else						//right
						if(!get_background_right(xPos_sprite,yPos_sprite))
							dir_sprite = 3'd1;
						else
							dir_sprite = 3'd6;//right&up at the same time
				end
			else if(x_diff <= y_diff && dir_temp[1] == 1)//no block on down
				if(!get_background_down(xPos_sprite,yPos_sprite))
					dir_sprite = 3'd3;
				else//down
				begin
					if(dir_temp[0] == 0) //left
						if(!get_background_left(xPos_sprite,yPos_sprite))
							dir_sprite = 3'd0;
						else
							dir_sprite = 3'd5;//left&down at the same time
					else
						if(!get_background_right(xPos_sprite,yPos_sprite))
							dir_sprite = 3'd1;
						else
							dir_sprite = 3'd7;//right&down at the same time
				end
			case(dir_sprite)
			3'd0: begin
			if(!get_background_left(xPos_sprite, yPos_sprite))
			xPos_sprite <= xPos_sprite - 1; //Left
			end
			3'd1: begin
			if(!get_background_right(xPos_sprite, yPos_sprite))
			xPos_sprite <= xPos_sprite + 1; //Right
			end
			3'd2: begin
			if(!get_background_up(xPos_sprite, yPos_sprite))
			yPos_sprite <= yPos_sprite - 1; //Up
			end
			3'd3: begin
			if(!get_background_down(xPos_sprite, yPos_sprite))
			yPos_sprite <= yPos_sprite + 1; //Down
			end
			3'd4:begin
				xPos_sprite <= xPos_sprite - 1; //Left
				yPos_sprite <= yPos_sprite -1;	//up
			end
			3'd5:begin
				xPos_sprite <= xPos_sprite -1;	//left
				yPos_sprite <= yPos_sprite + 1;	//down
			end
			3'd6:begin
				xPos_sprite <= xPos_sprite + 1;	//right
				yPos_sprite <= yPos_sprite - 1;	//up
			end
			3'd7:begin
				xPos_sprite <= xPos_sprite + 1;	//right
				yPos_sprite <= yPos_sprite + 1; //down
			end
			endcase
		end
	end
end

//Track judgement of sprite2
always @(posedge clk or negedge reset_n) begin

	if(!reset_n) begin
		xPos_sprite2 <= 5;
		yPos_sprite2 <= 5;
		mClk_sprite2 <= 0;
	end
	else if(clkCount == 8'd1) begin
		mClk_sprite2 <= mClk_sprite2 + 1;            
		if(mClk_sprite2 == 0) begin

				if(xPos_sprite2 < xPos_man2) begin
					dir_temp2[0] = 1;
					x_diff2 = xPos_man2 - xPos_sprite2;
				end
				else begin
					dir_temp2[0] = 0;
					x_diff2 = xPos_sprite2 - xPos_man2;
				end
				if(yPos_sprite2 < yPos_man2) begin
					dir_temp2[1] = 1;
					y_diff2 = yPos_man2 - yPos_sprite2;
				end
				else begin
					dir_temp2[1] = 0;
					y_diff2 = yPos_sprite2 - yPos_man2;
				end
			
			//find a path
			//left
			if(x_diff2 > y_diff2 && dir_temp2[0] == 0 && !get_background_left(xPos_sprite2,yPos_sprite2)) //no block on left
				dir_sprite2 = 3'd0;
			else if(x_diff2 > y_diff2 && dir_temp2[0] == 0 && get_background_left(xPos_sprite2,yPos_sprite2)) //
			begin
				if(dir_temp2[1] == 0)
						if(!get_background_up(xPos_sprite2,yPos_sprite2))
							dir_sprite2 = 3'd2;
						else
							dir_sprite2 = 3'd4;
				else
						if(!get_background_down(xPos_sprite2,yPos_sprite2))
							dir_sprite2 = 3'd3;
						else
							dir_sprite2 = 3'd5;
			end
			else if(x_diff2 > y_diff2 && dir_temp2[0] == 1 && !get_background_right(xPos_sprite2,yPos_sprite2)) 
				dir_sprite2 = 3'd1;
			else if(x_diff2 > y_diff2 && dir_temp2[0] == 1 && get_background_right(xPos_sprite2,yPos_sprite2))
			begin
				if(dir_temp2[1] == 0)
						if(!get_background_up(xPos_sprite2,yPos_sprite2))
							dir_sprite2 = 3'd2;
						else
							dir_sprite2 = 3'd6;
				else
						if(!get_background_down(xPos_sprite2,yPos_sprite2))
							dir_sprite2 = 3'd3;
						else
							dir_sprite2 = 3'd7;
			end
			else if(x_diff2 <= y_diff2 && dir_temp2[1] == 0 && !get_background_up(xPos_sprite2,yPos_sprite2))
				dir_sprite2 = 3'd2;
			else if(x_diff2 <= y_diff2 && dir_temp2[1] == 0 && get_background_up(xPos_sprite2,yPos_sprite2))
			begin
				if(dir_temp2[0] == 0)
					if(!get_background_left(xPos_sprite2,yPos_sprite2))
						dir_sprite2 = 3'd0;
					else
						dir_sprite2 = 3'd4;
				else
					if(!get_background_right(xPos_sprite2,yPos_sprite2))
						dir_sprite2 = 3'd1;
					else
						dir_sprite2 = 3'd6;
			end
			else if(x_diff2 <= y_diff2 && dir_temp2[1] == 1 && !get_background_down(xPos_sprite2,yPos_sprite2))
				dir_sprite2 = 3'd3;
			else if(x_diff2 <= y_diff2 && dir_temp2[1] == 1 && get_background_down(xPos_sprite2,yPos_sprite2))
			begin
				if(dir_temp2[0] == 0)
					if(!get_background_left(xPos_sprite2,yPos_sprite2))
						dir_sprite2 = 3'd0;
					else
						dir_sprite2 = 3'd5;
				else
					if(!get_background_right(xPos_sprite2,yPos_sprite2))
						dir_sprite2 = 3'd1;
					else
						dir_sprite2 = 3'd7;
			end
			case(dir_sprite2)
			3'd0: begin
			if(!get_background_left(xPos_sprite2, yPos_sprite2))
			xPos_sprite2 <= xPos_sprite2 - 1; //Left
			end
			3'd1: begin
			if(!get_background_right(xPos_sprite2, yPos_sprite2))
			xPos_sprite2 <= xPos_sprite2 + 1; //Right
			end
			3'd2: begin
			if(!get_background_up(xPos_sprite2, yPos_sprite2))
			yPos_sprite2 <= yPos_sprite2 - 1; //Up
			end
			3'd3: begin
			if(!get_background_down(xPos_sprite2, yPos_sprite2))
			yPos_sprite2 <= yPos_sprite2 + 1; //Down
			end
			3'd4:begin
				xPos_sprite2 <= xPos_sprite2 - 1; //Left
				yPos_sprite2 <= yPos_sprite2 -1;	//up
			end
			3'd5:begin
				xPos_sprite2 <= xPos_sprite2 -1;	//left
				yPos_sprite2 <= yPos_sprite2 + 1;	//down
			end
			3'd6:begin
				xPos_sprite2 <= xPos_sprite2 + 1;	//right
				yPos_sprite2 <= yPos_sprite2 - 1;	//up
			end
			3'd7:begin
				xPos_sprite2 <= xPos_sprite2 + 1;	//right
				yPos_sprite2 <= yPos_sprite2 + 1; //down
			end
			endcase
		end
	end
end

//Write the objects (bomb man, bomb man2, sprite, etc.) into the object ram
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		oObjRam_addr <= 0;
		oObjRam_data <= 0;
		oObjRam_we   <= 0;
		fsm_objWR    <= 0;
	end
	else begin
		case(fsm_objWR) //state machine
		4'd0: begin //Idle state
			oObjRam_we <= 0;
			if(clkCount == 8'd16) fsm_objWR <= 4'd1;
		end
		4'd1: begin //Write man
			oObjRam_we   <= 1;
			oObjRam_addr <= 0;
			oObjRam_data <= {1'b1, 3'd0, xPos_man, yPos_man};
			fsm_objWR    <= 4'd2;
		end
		4'd2: begin //Write sprite
			oObjRam_we   <= 1;
			oObjRam_addr <= 1;
			oObjRam_data <= {1'b1, 3'd1, xPos_sprite, yPos_sprite};
			fsm_objWR    <= 4'd3;
		end
		4'd3: begin //Write man 2
			oObjRam_we 	 <= 1;
			oObjRam_addr <= 2;
			oObjRam_data <= {1'b1, 3'd2, xPos_man2, yPos_man2};
			fsm_objWR 	 <= 4'd4;
		end
		4'd4: begin//Write sprite2
			oObjRam_we   <= 1;
			oObjRam_addr <= 3;
			oObjRam_data <= {1'b1, 3'd3, xPos_sprite2, yPos_sprite2};
			fsm_objWR    <= 4'd0;    
		end
		default: fsm_objWR <= 4'd0;
		endcase
	end
end

//Function to get barrier of the background
function get_background_up;
	input [4: 0] x;
	input [3: 0] y;
begin
	if(y == 0) get_background_up = 1'b1;
    else if(y == 1 && (x >= 5 && x <=14)) get_background_up = 1'b1;
    else if(y == 3 && (x == 8 || x == 11)) get_background_up = 1'b1;
    else if(y == 4 && (x == 3 || x == 7 || x == 12 || x == 16)) get_background_up = 1'b1;
    else if(y == 5 && (x == 8 || x == 11)) get_background_up = 1'b1;
    else if(y == 6 && (x == 5 || x == 14)) get_background_up = 1'b1;
    else if(y == 7 && (x == 6 || x == 13)) get_background_up = 1'b1;
    else if(y == 8 && (x == 9 || x == 10)) get_background_up = 1'b1;
	else if(y == 9 && ( x == 6 ||x == 13)) get_background_up = 1'b1;
    else if(y == 10 && (x == 0 || x == 5 || x == 14 || x == 19)) get_background_up = 1'b1;
    else if(y == 11 && (x == 8 || x == 11)) get_background_up = 1'b1;
    else if(y == 12 && (x == 3 || x == 7 || x == 12 || x == 16)) get_background_up = 1'b1;
    else if(y == 13 && (x == 8 || x == 11)) get_background_up = 1'b1;
    else get_background_up = 1'b0;
end
endfunction //get_background_up

function get_background_down;
    input [4: 0] x;
    input [3: 0] y;
begin
    if(y == 14) get_background_down = 1'b1;
    else if(y == 13 && (x >= 5 && x <= 14)) get_background_down = 1'b1;
    else if(y == 11 && (x == 8 || x == 11)) get_background_down = 1'b1;
    else if(y == 10 && (x == 3 || x == 7 || x == 12 || x == 16)) get_background_down = 1'b1;
    else if(y == 9 && (x == 8 || x == 11)) get_background_down = 1'b1;
    else if(y == 8 && (x == 5 || x == 14)) get_background_down = 1'b1;
    else if(y == 7 && (x == 6 || x == 13)) get_background_down = 1'b1;
    else if(y == 6 && (x == 9 || x == 10)) get_background_down = 1'b1;
    else if(y == 5 && ( x == 6 || x == 13)) get_background_down = 1'b1;
    else if(y == 4 && (x == 0 || x == 5 || x == 14 || x == 19)) get_background_down = 1'b1;
    else if(y == 3 && (x == 8 || x == 11)) get_background_down = 1'b1;
    else if(y == 2 && (x == 3 || x == 7 || x == 12 || x == 16)) get_background_down = 1'b1;
    else if(y == 1 && (x == 8 || x == 11)) get_background_down = 1'b1;
    else get_background_down = 1'b0;
end
endfunction //get_background_down

function get_background_left;
    input [4: 0] x;
    input [3: 0] y;
begin
    if(x == 0) get_background_left = 1'b1;
    else if(x == 1 && (y >= 5 && y <= 9)) get_background_left = 1'b1;
    else if(x == 4 && (y == 3 || y == 11)) get_background_left = 1'b1; 
    else if(x == 6 && (y == 5 || y == 9)) get_background_left = 1'b1;
    else if(x == 7 && (y == 6 || y == 8)) get_background_left = 1'b1;
    else if(x == 8 && (y == 3 || y == 11)) get_background_left = 1'b1;
    else if(x == 9 && (y == 2 || y == 3 || y == 4 || y == 10 || y == 11 || y ==12)) get_background_left =1'b1;
    else if(x == 11 && y == 7) get_background_left = 1'b1;
    else if(x == 12 && (y == 2 || y == 4 || y ==10 || y == 12)) get_background_left =1'b1;
    else if(x == 13 && (y == 3 || y == 11)) get_background_left = 1'b1;
    else if(x == 14 && (y == 6 || y == 8)) get_background_left =1'b1;
    else if(x == 15 && (y == 0 || y == 5 || y == 9 || y == 14)) get_background_left = 1'b1;
    else if(x == 17 && (y == 3 || y == 11)) get_background_left = 1'b1;
    else get_background_left = 1'b0;
end
endfunction //get_background_left

function get_background_right;
    input [4: 0] x;
    input [3: 0] y;
begin
    if(x == 19) get_background_right = 1'b1;
    else if(x == 18 && (y >= 5 && y <= 9)) get_background_right = 1'b1;
    else if(x == 15 && (y == 3 || y == 11)) get_background_right = 1'b1; 
    else if(x == 13 && (y == 5 || y == 9)) get_background_right = 1'b1;
    else if(x == 12 && (y == 6 || y == 8)) get_background_right = 1'b1;
    else if(x == 11 && (y == 3 || y == 11)) get_background_right = 1'b1;
    else if(x == 10 && (y == 2 || y == 3 || y == 4 || y == 10 || y == 11 || y ==12)) get_background_right =1'b1;
    else if(x == 8 && y == 7) get_background_right = 1'b1;
    else if(x == 7 && (y == 2 || y == 4 || y ==10 || y == 12)) get_background_right = 1'b1;
    else if(x == 6 && (y == 3 || y == 11)) get_background_right = 1'b1;
    else if(x == 5 && (y == 6 || y == 8)) get_background_right = 1'b1;
    else if(x == 4 && (y == 0 || y=== 5 || y == 9 || y == 14)) get_background_right = 1'b1;
    else if(x == 2 && (y == 3 || y == 11)) get_background_right = 1'b1;
    else get_background_right = 1'b0;
end
endfunction //get_background_right

//function to judge collision
function Collision;
	input [4:0] man_x;
	input [3:0] man_y;
	input [4:0] sprite_x;
	input [3:0] sprite_y;
begin
	if(man_x == sprite_x && man_y == sprite_y)
	Collision = 1'b1;
	else Collision =1'b0;
end
endfunction 
endmodule //game_controller

