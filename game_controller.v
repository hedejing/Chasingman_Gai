/* @brief
 * @input  
 * @output
 * @remark  
 */
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

reg  [ 4: 0] xPos_bombMan;  //X position of bomb man (1 - 17)
reg  [ 3: 0] yPos_bombMan;  //Y position of bomb man (1 - 13)

reg  [ 4: 0] xPos_bombMan2; //X position of bomb man2 (1 - 17)
reg  [ 3: 0] yPos_bombMan2; //Y position of bomb man2 (1 - 13)

reg  [ 4: 0] xPos_sprite;   //X position of sprite (1 - 17)
reg  [ 3: 0] yPos_sprite;   //Y position of sprite (1 - 13)
reg  [ 1: 0] dir_sprite;    //Moving direction of sprite (0: L, 1: R, 2: U, 3: D)
reg  [ 4: 0] mClk_sprite;   //Sprite moving clock divider

reg  [ 4: 0] xPos_sprite2;   //X position of sprite (1 - 17)
reg  [ 3: 0] yPos_sprite2;   //Y position of sprite (1 - 13)
reg  [ 1: 0] dir_sprite2;    //Moving direction of sprite (0: L, 1: R, 2: U, 3: D)
reg  [ 4: 0] mClk_sprite2;   //Sprite moving clock divider


reg  [ 3: 0] fsm_objWR;     //State machine of object ram writing

//assign oBkg_sel = change;
always @(posedge clk or negedge reset_n) begin			//这部分还需新的结束画面，oBke_sel的值要相应地改
	if(!reset_n) oBkg_sel=0;
	else begin 
	if(Collision(xPos_bombMan,yPos_bombMan,xPos_sprite,yPos_sprite)
		||Collision(xPos_bombMan,yPos_bombMan,xPos_sprite2,yPos_sprite2)) oBkg_sel=1;  //man die
	if(Collision(xPos_bombMan2,yPos_bombMan2,xPos_sprite2,yPos_sprite2)
		||Collision(xPos_bombMan2,yPos_bombMan2,xPos_sprite,yPos_sprite)) oBkg_sel=1;	//man2 die
	end
end


reg  [4: 0] x_diff;
reg  [3: 0] y_diff;
reg  [1: 0] dir_temp;

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
		keyVal <= ~iKEY & (lastSW ^ ~iKEY);
	end

end
	
//Track judgement of bomb man
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		xPos_bombMan <= 1;
		yPos_bombMan <= 1;
	end
	else if(clkCount == 8'd1) begin
		case(keyVal[3: 0])
		4'b1000: begin //UP
			if(!get_background(xPos_bombMan, yPos_bombMan - 1) && 
				!(xPos_bombMan == xPos_bombMan2 && yPos_bombMan - 1 == yPos_bombMan2))
				yPos_bombMan <= yPos_bombMan - 1;
		end
		4'b0100: begin //DOWN
			if(!get_background(xPos_bombMan, yPos_bombMan + 1) &&
				!(xPos_bombMan == xPos_bombMan2 && yPos_bombMan + 1 == yPos_bombMan2))
				yPos_bombMan <= yPos_bombMan + 1;
		end
		4'b0010: begin //LEFT
			if(!get_background(xPos_bombMan - 1, yPos_bombMan) &&
				!(xPos_bombMan - 1 == xPos_bombMan2 && yPos_bombMan == yPos_bombMan2))
				xPos_bombMan <= xPos_bombMan - 1;
		end
		4'b0001: begin //RIGHT
			if(!get_background(xPos_bombMan + 1, yPos_bombMan) &&
				!(xPos_bombMan + 1 == xPos_bombMan2 && yPos_bombMan == yPos_bombMan2))
				xPos_bombMan <= xPos_bombMan + 1;
		end
		endcase
	end
end

//Track judgement of bomb man 2
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		xPos_bombMan2 <= 17;
		yPos_bombMan2 <= 13;
	end
	else if(clkCount == 8'd1) begin
		case(keyVal[7: 4])
		4'b1000: begin //UP
			if(!get_background(xPos_bombMan2, yPos_bombMan2 - 1) &&
				!(xPos_bombMan2 == xPos_bombMan && yPos_bombMan2 - 1 == yPos_bombMan))
				yPos_bombMan2 <= yPos_bombMan2 - 1;
		end
		4'b0100: begin //DOWN
			if(!get_background(xPos_bombMan2, yPos_bombMan2 + 1) &&
				!(xPos_bombMan2 == xPos_bombMan && yPos_bombMan2 - 1 == yPos_bombMan))
				yPos_bombMan2 <= yPos_bombMan2 + 1;
		end
		4'b0010: begin //LEFT
			if(!get_background(xPos_bombMan2 - 1, yPos_bombMan2) &&
				!(xPos_bombMan2 - 1 == xPos_bombMan && yPos_bombMan2 == yPos_bombMan))
				xPos_bombMan2 <= xPos_bombMan2 - 1;
		end
		4'b0001: begin //RIGHT
			if(!get_background(xPos_bombMan2 + 1, yPos_bombMan2) &&
				!(xPos_bombMan2 + 1 == xPos_bombMan && yPos_bombMan2 == yPos_bombMan))
				xPos_bombMan2 <= xPos_bombMan2 + 1;
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
			if(xPos_sprite[0] && yPos_sprite[0]) begin//Locations to change moving direction
				if(xPos_sprite < xPos_bombMan) begin
					dir_temp[0] = 1;
					x_diff = xPos_bombMan - xPos_sprite;
				end
				else begin
					dir_temp[0] = 0;
					x_diff = xPos_sprite - xPos_bombMan;
				end
				if(yPos_sprite < yPos_bombMan) begin
					dir_temp[1] = 1;
					y_diff = yPos_bombMan - yPos_sprite;
				end
				else begin
					dir_temp[1] = 0;
					y_diff = yPos_sprite - yPos_bombMan;
				end
			
				if(x_diff > y_diff) begin //X has higher priority
					if(dir_temp[0]) dir_sprite = 2'd1;
					else dir_sprite = 2'd0;
				end
				else begin //Y has higher priority
					if(dir_temp[1]) dir_sprite = 2'd3;
					else dir_sprite = 2'd2;
				end
			end
			
			case(dir_sprite)
			2'd0: begin
			if(!get_background(xPos_sprite - 1, yPos_sprite))
			xPos_sprite <= xPos_sprite - 1; //Left
			end
			2'd1: begin
			if(!get_background(xPos_sprite + 1, yPos_sprite))
			xPos_sprite <= xPos_sprite + 1; //Right
			end
			2'd2: begin
			if(!get_background(xPos_sprite, yPos_sprite - 1))
			yPos_sprite <= yPos_sprite - 1; //Up
			end
			2'd3: begin
			if(!get_background(xPos_sprite, yPos_sprite + 1))
			yPos_sprite <= yPos_sprite + 1; //Down
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
		 if(xPos_sprite2[0] && yPos_sprite2[0]) begin //Locations to change moving direction
				if(xPos_sprite2 < xPos_bombMan2) begin
					dir_temp2[0] = 1;
					x_diff2 = xPos_bombMan2 - xPos_sprite2;
				end
				else begin
					dir_temp2[0] = 0;
					x_diff2 = xPos_sprite2 - xPos_bombMan2;
				end
				if(yPos_sprite2 < yPos_bombMan2) begin
					dir_temp2[1] = 1;
					y_diff2 = yPos_bombMan2 - yPos_sprite2;
				end
				else begin
					dir_temp2[1] = 0;
					y_diff2 = yPos_sprite2 - yPos_bombMan2;
				end
			
				if(x_diff2 > y_diff2) begin //X has higher priority
					if(dir_temp2[0]) dir_sprite2 = 2'd1;
					else dir_sprite2 = 2'd0;
				end
				else begin //Y has higher priority
					if(dir_temp2[1]) dir_sprite2 = 2'd3;
					else dir_sprite2 = 2'd2;
				end
			end
			
			case(dir_sprite2)
			2'd0: begin
			if(!get_background(xPos_sprite2 - 1, yPos_sprite2))
			xPos_sprite2 <= xPos_sprite2 - 1; //Left
			end
			2'd1: begin
			if(!get_background(xPos_sprite2 + 1, yPos_sprite2))
			xPos_sprite2 <= xPos_sprite2 + 1; //Right
			end
			2'd2: begin
			if(!get_background(xPos_sprite2 , yPos_sprite2 - 1))
			yPos_sprite2 <= yPos_sprite2 - 1; //Up
			end
			2'd3: begin
			if(!get_background(xPos_sprite2 , yPos_sprite2 + 1))
			yPos_sprite2 <= yPos_sprite2 + 1; //Down
			end
			endcase
		end
	end
end

//reg  [ 4: 0] xPos_bomb1;    //X position of bomb 1 (1 - 17)
//reg  [ 3: 0] yPos_bomb1;    //Y position of bomb 1 (1 - 13)
//reg  [ 1: 0] state_bomb1;   //State of bomb 1 (0: Disable, 1: Active, 2: Exploded)
//reg  [ 7: 0] mClk_bomb1;    //Bomb 1 clock divider

//Write the objects (bomb man, bomb man2, sprite, bomb, etc.) into the object ram
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		oObjRam_addr <= 0;
		oObjRam_data <= 0;
		oObjRam_we   <= 0;
		fsm_objWR    <= 0;
	end
	else begin
		case(fsm_objWR)
		4'd0: begin //Idle state
			oObjRam_we <= 0;
			if(clkCount == 8'd16) fsm_objWR <= 4'd1;
		end
		4'd1: begin //Write bomb man
			oObjRam_we   <= 1;
			oObjRam_addr <= 0;
			oObjRam_data <= {1'b1, 3'd0, xPos_bombMan, yPos_bombMan};
			fsm_objWR    <= 4'd2;
		end
		4'd2: begin //Write sprite
			oObjRam_we   <= 1;
			oObjRam_addr <= 1;
			oObjRam_data <= {1'b1, 3'd1, xPos_sprite, yPos_sprite};
			fsm_objWR    <= 4'd3;
		end
		4'd3: begin //Write bomb man 2
			oObjRam_we 	 <= 1;
			oObjRam_addr <= 2;
			oObjRam_data <= {1'b1, 3'd0, xPos_bombMan2, yPos_bombMan2};
			fsm_objWR 	 <= 4'd4;
		end
		4'd4: begin//Write sprite2
			oObjRam_we   <= 1;
			oObjRam_addr <= 3;
			oObjRam_data <= {1'b1, 3'd1, xPos_sprite2, yPos_sprite2};
			fsm_objWR    <= 4'd0;    
		end
		default: fsm_objWR <= 4'd0;
		endcase
	end
end

//Function to get barrier of the background
function get_background;
	input [4: 0] x;
	input [3: 0] y;
begin
	if(x == 0 || x == 18) get_background = 1'b1;
	else if(y == 0 || y == 14) get_background = 1'b1;
	else if((x[0] == 0) && (y[0] == 0)) get_background = 1'b1;
	else get_background = 1'b0;
end
endfunction //get_background
//Function to determine collision
function Collision;
	input [4:0] bombman_x;
	input [3:0] bombman_y;
	input [4:0] sprite_x;
	input [3:0] sprite_y;
begin
	if(bombman_x == sprite_x && bombman_y == sprite_y)
	Collision = 1'b1;
	else Collision =1'b0;
end
endfunction 

endmodule //game_controller

