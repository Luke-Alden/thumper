---------------------------------------------------------------------------
-- FILE    : server_logger.adb
-- SUBJECT : Body of a log management package.
-- AUTHOR  : (C) Copyright 2022 by Peter Chapin
--
-- Please send comments or bug reports to
--
--      Peter Chapin <chapinp@acm.org>
---------------------------------------------------------------------------
pragma SPARK_Mode(Off);

with Ada.Text_IO;
with Ada.Calendar;

use Ada.Calendar;

package body Server_Logger is

   function Format_Timestamp return string is
      Now  : Time:= Clock;
      Now_Year   : Year_Number := Year(Now);
      Now_Month  : Month_Number:= Month(Now);
      Now_Day    : Day_Number  := Day(Now);
      Now_Seconds: Integer     := Integer(Seconds(Now));
      New_Hour   : String      := Integer'Image(Now_Seconds / 3600);
      New_Minute : String      := Integer'Image((Now_Seconds mod 3600) / 60);
      New_Seconds: String      := Integer'Image((Now_Seconds / 3600) mod 60);
      Date : String := (Integer'Image(Now_Year) & "-" & Integer'Image(Now_Month)  & "-" & Integer'Image(Now_Day) & "-" & New_Hour & "-" & New_Minute & "-" & New_Seconds);
   begin
      return Date;
   end Format_Timestamp;


   procedure Write_Error(Message : in String) is
   begin
      Ada.Text_IO.Put_Line("*** ERROR: " & Message);
   end Write_Error;

   procedure Write_Information(Message : in String) is
      Timestamp : String := Format_Timestamp;
   begin
      Ada.Text_IO.Put_Line("Summary: " & Message & Timestamp);
   end Write_Information;

   procedure Write_Warning(Message : in String) is
   begin
      Ada.Text_IO.Put_Line("*** Warning: " & Message);
   end Write_Warning;

end Server_Logger;
