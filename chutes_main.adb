with MaRTE_OS;
with Text_IO; use Text_IO;
with Chute;  use Chute; 
with Ada.Calendar; use Ada.Calendar; 
with Ada.Unchecked_Deallocation; use Ada;

procedure Chutes_Main is
    Char_Received : Boolean := False;
    C : Character := ' ';
    Start_Time : Time;
    Metal_Count : Integer := 0; 
    Glass_Count : Integer := 0; 

    protected Timer is 
        entry Wait_Time_Out; 
        procedure enable_time_out; 
        private 
        Timed_out : Boolean := False; 
    end Timer; 

    protected body Timer is 
        entry Wait_Time_Out when Timed_out is 
        begin 
            null;
        end Wait_Time_Out;

        procedure enable_time_out is 
        begin 
            Timed_out := True; 
        end enable_time_out; 
    end Timer; 

    procedure Start is 

        type node;  
        type node_ptr is access node; 
        type node is record 
            data : Ball_Sensed; 
            ptr  : node_ptr; 
        end record;
        type list_type is record 
            head : node_ptr; 
            tail : node_ptr; 
        end record;
        List : list_type; 
        
        protected Queue is 
            procedure push(Data : in Ball_Sensed); 
            procedure pop(Ret : out Ball_Sensed); 
        end Queue; 

        protected body Queue is 
            procedure push(Data : in Ball_Sensed) is
                Temp : node_ptr := new Node'(Data, null); 
            begin 
                if list.tail = null then 
                    list.tail := Temp; 
                end if; 
                if list.head /= null then 
                    list.head.ptr := Temp; 
                end if;
                list.head := Temp; 
            end push; 

            procedure pop(Ret : out Ball_Sensed) is 
                procedure free is new Unchecked_Deallocation(node, node_ptr); 
                Temp : node_ptr := list.tail; 
            begin
                if List.Head = null then 
                    Put_Line("Error: Queue Empty"); 
                end if; 
                Ret := List.Tail.data;
                List.Tail := List.Tail.ptr;
                if List.Tail = null then 
                    List.Head := null; 
                end if;
                Free(Temp); 
            end pop; 
        end Queue;


        protected Ball_Sensor is 
            entry wait_for_metal; 
            entry wait_for_proximity; 
            procedure metal_sensor_activated; 
        private 
            metal_detected : Boolean := False; 
            proximity_detected : Boolean := False;
        end Ball_Sensor; 

        protected body Ball_Sensor is 
            entry wait_for_metal when metal_detected is 
            begin 
                Queue.push(Metal); 
                metal_detected := False;
            end wait_for_metal; 

            entry wait_for_proximity when proximity_detected is 
            begin 
                proximity_detected := False; 
            end wait_for_proximity; 

            procedure metal_sensor_activated is 
            begin
                metal_detected := True; 
            end metal_sensor_activated;
        end Ball_Sensor; 


        task Release;

        task body Release is 
            select_entry_time : Time; 
        begin 
            Start_Time := Clock; 
            select 
                Timer.Wait_Time_Out;
            then abort 
                loop 
                    hopper_load; 
                    delay 0.2; 
                    hopper_unload; 
                    select_entry_time := Clock; 
                    select 
                    delay 0.8; 
                        Queue.push(Unknown); 
                    then abort 
                        Ball_Sensor.wait_for_metal; 
                    end select; 
                    delay until(select_entry_time + 0.8); 
                end loop;
            end select;
        end Release; 

        task Identify_Ball;

        task body Identify_Ball is 
            ball_type : Ball_Sensed; 
            ball_time : Time;
            ball_rec  : Ball_Sensed; 
        begin 
            loop 
                select 
                    delay 5.0; 
                    Timer.enable_time_out; 
                    exit; 
                then abort 
                    Get_Next_Sensed_Ball(ball_type , ball_time);
                    if ball_type = Metal then 
                        Ball_Sensor.metal_sensor_activated;
                    else 
                        Queue.pop(ball_rec); 
                        if ball_rec = Metal then 
                            Sorter_Metal;
                            Metal_Count := Metal_Count + 1; 
                        end if; 
                        if ball_rec = Unknown then 
                            Sorter_Glass;
                            Glass_Count := Glass_Count + 1; 
                        end if; 
                    end if;
                end select;
            end loop; 
        end Identify_Ball; 

    begin 
        null; 
    end Start; 


begin 
    hopper_unload; 
    Text_IO.New_Line;
    Put_Line("Press Any Key To Continue..."); 
    loop
        Get_Immediate(C, Char_Received);
        if Char_Received then
            select 
                Timer.Wait_Time_Out; 
                exit;
            then abort 
                Start; 
            end select;
        end if;
    end loop; 
    Put_Line("Finished Sorting"); 
    Put_Line("Metal Balls Sorted: " & Integer'Image(Metal_Count)); 
    Put_Line("Glass Balls Sorted: " & Integer'Image(Glass_Count)); 
end Chutes_Main;
