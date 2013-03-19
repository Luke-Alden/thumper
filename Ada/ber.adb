---------------------------------------------------------------------------
-- FILE    : ber.adb
-- SUBJECT : Body of a package that encapsulates subprograms that handle the basic encoding rules.
-- AUTHOR  : (C) Copyright 2013 by Peter Chapin and John McCormick
--
-- Please send comments or bug reports to
--
--      Peter Chapin <PChapin@vtc.vsc.edu>
---------------------------------------------------------------------------

package body BER is

   function Make_Leading_Identifier
     (Tag_Class       : Tag_Class_Type;
      Structured_Flag : Structured_Flag_Type;
      Tag             : Leading_Number_Type) return Network.Octet is

      type Tag_Class_Lookup_Type is array(Tag_Class_Type) of Network.Octet;
      type Structured_Flag_Lookup_Type is array(Structured_Flag_Type) of Network.Octet;
      type Leading_Number_Lookup_Type is array(Leading_Number_Type) of Network.Octet;

      Tag_Class_Lookup_Table : constant Tag_Class_Lookup_Type := Tag_Class_Lookup_Type'
        (Class_Universal        => 2#0000_0000#,
         Class_Application      => 2#0100_0000#,
         Class_Context_Specific => 2#1000_0000#,
         Class_Private          => 2#1100_0000#);

      Structured_Flag_Lookup_Table : constant Structured_Flag_Lookup_Type := Structured_Flag_Lookup_Type'
        (Primitive              => 2#0000_0000#,
         Constructed            => 2#0010_0000#);

      Leading_Number_Lookup_Table : constant Leading_Number_Lookup_Type := Leading_Number_Lookup_Type'
        (Tag_Reserved           =>  0,
         Tag_Boolean            =>  1,
         Tag_Integer            =>  2,
         Tag_Bit_String         =>  3,
         Tag_Octet_String       =>  4,
         Tag_Null               =>  5,
         Tag_Object_Identifier  =>  6,
         Tag_Object_Descriptor  =>  7,
         Tag_Instance_Of        =>  8,
         Tag_External           =>  8,  -- Same as Instance_Of
         Tag_Real               =>  9,
         Tag_Enumerated         => 10,
         Tag_Embedded_PDV       => 11,
         Tag_UTF8_String        => 12,
         Tag_Relative_OID       => 13,
         -- Values 14 .. 15 omitted (not defined?)
         Tag_Sequence           => 16,
         Tag_Sequence_Of        => 16,  -- Same as Sequence
         Tag_Set                => 17,
         Tag_Set_Of             => 17,  -- Same as Set
         Tag_Numeric_String     => 18,
         Tag_Printable_String   => 19,
         Tag_Teletex_String     => 20,
         Tag_T61_String         => 20,  -- Same as Teletex_String
         Tag_Videotex_String    => 21,
         Tag_IA5_String         => 22,
         Tag_UTC_Time           => 23,
         Tag_Generalized_Time   => 24,
         Tag_Graphic_String     => 25,
         Tag_Visible_String     => 26,
         Tag_ISO646_String      => 26,  -- Same as Visible_String
         Tag_General_String     => 27,
         Tag_Universal_String   => 28,
         Tag_Character_String   => 29,
         Tag_BMP_String         => 30,
         Tag_EXTENDED_TAG       => 31);


   begin
      return
        Tag_Class_Lookup_Table(Tag_Class)             or
        Structured_Flag_Lookup_Table(Structured_Flag) or
        Leading_Number_Lookup_Table(Tag);
   end Make_Leading_Identifier;


   procedure Split_Leading_Identifier
     (Value           : in  Network.Octet;
      Tag_Class       : out Tag_Class_Type;
      Structured_Flag : out Structured_Flag_Type;
      Tag             : out Leading_Number_Type;
      Status          : out Status_Type) is

      subtype Leading_Number_Range_Type is Network.Octet range 0 .. 31;
      type Leading_Number_Lookup_Type is array(Leading_Number_Range_Type) of Leading_Number_Type;
      Leading_Number_Lookup_Table : constant Leading_Number_Lookup_Type := Leading_Number_Lookup_Type'
        ( 0 => Tag_Reserved,
          1 => Tag_Boolean,
          2 => Tag_Integer,
          3 => Tag_Bit_String,
          4 => Tag_Octet_String,
          5 => Tag_Null,
          6 => Tag_Object_Identifier,
          7 => Tag_Object_Descriptor,
          8 => Tag_Instance_Of,        -- Could also be Tag_External
          9 => Tag_Real,
         10 => Tag_Enumerated,
         11 => Tag_Embedded_PDV,
         12 => Tag_UTF8_String,
         13 => Tag_Relative_OID,
         14 => Tag_Null,               -- 14 is undefined.
         15 => Tag_Null,               -- 15 is undefined.
         16 => Tag_Sequence,           -- Could also be Tag_Sequence_Of
         17 => Tag_Set,                -- Could also be Tag_Set_Of
         18 => Tag_Numeric_String,
         19 => Tag_Printable_String,
         20 => Tag_Teletex_String,     -- Could also be Tag_T61_String
         21 => Tag_Videotex_String,
         22 => Tag_IA5_String,
         23 => Tag_UTC_Time,
         24 => Tag_Generalized_Time,
         25 => Tag_Graphic_String,
         26 => Tag_Visible_String,     -- Could also be Tag_ISO646_String
         27 => Tag_General_String,
         28 => Tag_Universal_String,
         29 => Tag_Character_String,
         30 => Tag_BMP_String,
         31 => Tag_EXTENDED_TAG);

      procedure Set_Tag_Class
      --# global in Value; out Tag_Class;
      --# derives Tag_Class from Value;
      is
      begin
         -- Deal with the class.
         case (Value and 2#1100_0000#) is
            when 2#0000_0000# => Tag_Class := Class_Universal;
            when 2#0100_0000# => Tag_Class := Class_Application;
            when 2#1000_0000# => Tag_Class := Class_Context_Specific;
            when 2#1100_0000# => Tag_Class := Class_Private;
            when others => Tag_Class := Class_Universal;   -- Should never happen.
         end case;
      end Set_Tag_Class;

      procedure Set_Structured_Flag
      --# global in Value; out Structured_Flag;
      --# derives Structured_Flag from Value;
      is
      begin
         -- Deal with the structured flag.
         case (Value and 2#0010_0000#) is
            when 2#0000_0000# => Structured_Flag := Primitive;
            when 2#0010_0000# => Structured_Flag := Constructed;
            when others => Structured_Flag := Primitive;   -- Should never happen.
         end case;
      end Set_Structured_Flag;

      procedure Set_Tag
      --# global in Value; out Tag; in out Status;
      --# derives Tag    from Value &
      --#         Status from Value, Status;
      is
         Tag_Value : Leading_Number_Range_Type;
      begin
         -- Deal with the tag.
         Tag_Value := (Value and 2#0001_1111#);
         if Tag_Value = 14 or Tag_Value = 15 then
            Status := Bad_Identifier;
         end if;
         Tag := Leading_Number_Lookup_Table(Tag_Value);
      end Set_Tag;

   begin
      Status := Success;

      Set_Tag_Class;
      Set_Structured_Flag;
      Set_Tag;
   end Split_Leading_Identifier;


   procedure Get_Length_Value
     (Message : in  Network.Octet_Array;
      Index   : in  Natural;
      Stop    : out Natural;
      Length  : out Natural;
      Status  : out Status_Type) is

      subtype Length_Of_Length_Type is Positive range 1 .. 127;
      Length_Of_Length : Length_Of_Length_Type;

      function Convert_Length(Starting : in Natural; Octet_Count : in Length_Of_Length_Type) return Natural
      --# global in Message;
      --# pre Message'First < Starting and (Starting + (Octet_Count - 1)) <= Message'Last and
      --#      Octet_Count <= 4 and
      --#    ((Octet_Count  = 4) -> (Message(Starting) < 128));
      is
         Result : Natural := 0;
      begin
         for I in Length_Of_Length_Type range 1 .. Octet_Count loop
            --# assert 1 <= I and I <= 4 and
            --#    Message'First < Starting and (Starting + (Octet_Count - 1)) <= Message'Last and
            --#    ((Octet_Count < 4) -> (Result < 256**(I - 1))) and
            --#    ((Octet_Count = 4) -> ((I = 1 -> Result < 1) and (I > 1 -> Result < 128*256**(I - 2)))) and
            --#    Starting = Starting% and Octet_Count = Octet_Count%;
            Result := (Result * 256) + Natural(Message(Starting + (I - 1)));
         end loop;
         return Result;
      end Convert_Length;

   begin
      -- Check for indefinite length.
      if Message(Index) = 2#1000_0000# then
         Stop   := Index;
         Length := 0;
         Status := Indefinite_Length;

      -- Check for definite length, short form.
      elsif (Message(Index) and 2#1000_0000#) = 2#0000_0000# then
         Stop   := Index;
         Length := Natural(Message(Index));
         Status := Success;

      -- Check for definite length, long form, reserved value.
      elsif Message(Index) = 2#1111_1111# then
         Stop   := Index;
         Length := 0;
         Status := Bad_Length;

      -- We have definite length, long form, normal value.
      else
         --# check Message(Index) - 128 >= 1;
         Length_Of_Length := Length_Of_Length_Type(Message(Index) and 2#0111_1111#);

         -- Check that all length octets are in the array.
         if Index > Message'Last - Length_Of_Length then
            Stop   := Message'Last;  -- The desired value of Stop in this case is not specified in the documentation.
            Length := 0;
            Status := Bad_Length;

         -- Check that the value of the length is not too large (here we assume 32 bit Naturals).
         -- TODO: It is allowed to encode small lengths with a lot of leading zeros so Length_Of_Length > 4 might be ok.
         elsif Length_Of_Length > 4 or (Length_Of_Length = 4 and Message(Index + 1) >= 128) then
            Stop   := Index + Length_Of_Length;
            Length := 0;
            Status := Unimplemented_Length;

         -- Convert the length into a single Natural.
         else
            Stop   := Index + Length_Of_Length;
            Length := Convert_Length(Index + 1, Length_Of_Length);
            Status := Success;
         end if;
      end if;
   end Get_Length_Value;

end BER;