--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with VSS.JSON.Pull_Readers.JSON5;
with VSS.JSON.Streams;
with VSS.Strings.Character_Iterators;
with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;
with VSS.String_Vectors;
with VSS.Text_Streams.File_Input;

with RTG.Diagnostics;

package body RTG.Runtime_Reader is

   ----------
   -- Read --
   ----------

   procedure Read
     (File      : GNATCOLL.VFS.Virtual_File;
      Runtime   : in out RTG.Runtime.Runtime_Descriptor;
      Tasking   : in out RTG.Tasking.Tasking_Descriptor;
      Startup   : in out RTG.Startup.Startup_Descriptor;
      System    : in out RTG.System.System_Descriptor;
      Scenarios : out RTG.Scenario_Maps.Map)
   is
      use all type VSS.JSON.Streams.JSON_Stream_Element_Kind;
      use type VSS.Strings.Virtual_String;

      Input  : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader : VSS.JSON.Pull_Readers.JSON5.JSON5_Pull_Reader;

      procedure Read_Configuration
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Read_Runtime
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Read_Tasking
        with Pre  => Reader.Element_Kind = Start_Object,
             Post => Reader.Element_Kind = End_Object;

      procedure Read_Files_Section
        (Files : in out RTG.File_Descriptor_Vectors.Vector)
           with Pre  => Reader.Element_Kind = Start_Object,
                Post => Reader.Element_Kind = End_Object;

      procedure Read_System_Section
        (System : in out RTG.System.System_Descriptor)
           with Pre  => Reader.Element_Kind = Start_Object,
                Post => Reader.Element_Kind = End_Object;

      procedure Read_System_Restrictions_Section
        (System : in out RTG.System.System_Descriptor)
           with Pre  => Reader.Element_Kind = Start_Object,
                Post => Reader.Element_Kind = End_Object;

      procedure Read_Values
        (Values : in out VSS.String_Vectors.Virtual_String_Vector)
           with Pre  => Reader.Element_Kind = Start_Array,
                Post => Reader.Element_Kind = End_Array;

      procedure Parse_Memory_Descriptor
        (Values     : VSS.String_Vectors.Virtual_String_Vector;
         Descriptor : in out RTG.Memory_Descriptor);

      -----------------------------
      -- Parse_Memory_Descriptor --
      -----------------------------

      procedure Parse_Memory_Descriptor
        (Values     : VSS.String_Vectors.Virtual_String_Vector;
         Descriptor : in out RTG.Memory_Descriptor)
      is
         use type A0B.Types.Unsigned_64;

         Hex_Template : constant
           VSS.Strings.Templates.Virtual_String_Template :=
             "16#{}#";

         Value        : VSS.Strings.Virtual_String;
         First        : VSS.Strings.Character_Iterators.Character_Iterator;
         Last         : VSS.Strings.Character_Iterators.Character_Iterator;
         Success      : Boolean with Unreferenced;

      begin
         if Values.Length /= 2 then
            RTG.Diagnostics.Error ("must have two components");
         end if;

         --  Convert address

         Value := Values (1);

         if not Value.Starts_With ("0x") then
            RTG.Diagnostics.Error ("address must starts with 0x");
         end if;

         First.Set_At_First (Value);
         Success := First.Forward;
         Success := First.Forward;

         Descriptor.Address :=
           A0B.Types.Unsigned_64'Wide_Wide_Value
             (VSS.Strings.Conversions.To_Wide_Wide_String
                (Hex_Template.Format
                   (VSS.Strings.Formatters.Strings.Image
                      (Value.Tail_From (First)))));

         --  Convert size

         Value := Values (2);

         if Value.Starts_With ("DT_SIZE_K(")
           and Value.Ends_With (")")
         then
            First.Set_At_First (Value);
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;
            Success := First.Forward;

            Last.Set_At_Last (Value);
            Success := Last.Backward;

            Descriptor.Size :=
              1_024
              * A0B.Types.Unsigned_64'Wide_Wide_Value
                  (VSS.Strings.Conversions.To_Wide_Wide_String
                     (Value.Slice (First, Last)));

         else
            raise Program_Error;
         end if;
      end Parse_Memory_Descriptor;

      ------------------------
      -- Read_Configuration --
      ------------------------

      procedure Read_Configuration is
         Key   : VSS.Strings.Virtual_String;
         Depth : Natural := 0;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

               when String_Value =>
                  Scenarios.Insert (Key, Reader.String_Value);

               when Start_Array =>
                  if Key = "dt:/chosen/a0b,flash:reg" then
                     declare
                        Values : VSS.String_Vectors.Virtual_String_Vector;

                     begin
                        Read_Values (Values);
                        Parse_Memory_Descriptor (Values, Startup.Flash);
                     end;

                  elsif Key = "dt:/chosen/a0b,sram:reg" then
                     declare
                        Values : VSS.String_Vectors.Virtual_String_Vector;

                     begin
                        Read_Values (Values);
                        Parse_Memory_Descriptor (Values, Startup.SRAM);
                     end;

                  else
                     RTG.Diagnostics.Warning
                       ("configuration parameter `{}` is not an array",
                        Key);
                  end if;

               when Start_Object =>
                  if Key = "runtime" then
                     Read_Runtime;

                  elsif Key = "tasking" then
                     Read_Tasking;

                  else
                     Depth := @ + 1;
                  end if;

               when End_Object =>
                  exit when Depth = 0;

                  Depth := @ - 1;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Configuration;

      ------------------------
      -- Read_Files_Section --
      ------------------------

      procedure Read_Files_Section
        (Files : in out RTG.File_Descriptor_Vectors.Vector)
      is
         Information : RTG.File_Descriptor;

         procedure Read_File_Information
           with Pre  => Reader.Element_Kind = Start_Object,
                Post => Reader.Element_Kind = End_Object;

         ---------------------------
         -- Read_File_Information --
         ---------------------------

         procedure Read_File_Information is
            type Parameter_Kind is (Unknown, Crate, Path);

            Parameter : Parameter_Kind;
            Key       : VSS.Strings.Virtual_String;

         begin
            loop
               case Reader.Read_Next is
                  when Key_Name =>
                     Key := Reader.Key_Name;

                     if Key = "crate" then
                        Parameter := Crate;

                     elsif Key = "path" then
                        Parameter := Path;

                     else
                        RTG.Diagnostics.Warning
                          ("source file parameter `{}` is unknown", Key);
                     end if;

                  when String_Value =>
                     case Parameter is
                        when Unknown =>
                           null;

                        when Crate =>
                           Information.Crate := Reader.String_Value;

                        when Path =>
                           Information.Path := Reader.String_Value;
                     end case;

                  when End_Object =>
                     exit;

                  when others =>
                     raise Program_Error with Reader.Element_Kind'Img;
               end case;
            end loop;
         end Read_File_Information;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Information.File := Reader.Key_Name;
                  Information.Crate.Clear;
                  Information.Path.Clear;

               when Start_Object =>
                  Read_File_Information;
                  Files.Append (Information);

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Files_Section;

      ------------------
      -- Read_Runtime --
      ------------------

      procedure Read_Runtime is

         type Components is
           (None,
            Common_Required_Switches,
            Linker_Required_Switches,
            Component_System,
            Files);

         Component : Components := None;
         Key       : VSS.Strings.Virtual_String;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "common_required_switches" then
                     Component := Common_Required_Switches;

                  elsif Key = "files" then
                     Component := Files;

                  elsif Key = "linker_required_switches" then
                     Component := Linker_Required_Switches;

                  elsif Key = "system" then
                     Component := Component_System;

                  else
                     RTG.Diagnostics.Warning
                       ("`{}` is unknown runtime configuration parameter",
                        Key);
                  end if;

               when Start_Array =>
                  case Component is
                     when Common_Required_Switches =>
                        Read_Values (Runtime.Common_Required_Switches);

                     when Linker_Required_Switches =>
                        Read_Values (Runtime.Linker_Required_Switches);

                     when others =>
                        RTG.Diagnostics.Warning
                          ("`{}` runtime configuration parameter is not an array",
                           Key);
                        Reader.Skip_Current_Array;
                  end case;

               when Start_Object =>
                  case Component is
                     when Files =>
                        Read_Files_Section (Runtime.Runtime_Files);

                     when Component_System =>
                        Read_System_Section (System);

                     when others =>
                        RTG.Diagnostics.Warning
                          ("`{}` runtime configuration parameter is not object",
                        Key);
                        Reader.Skip_Current_Object;
                  end case;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Runtime;

      --------------------------------------
      -- Read_System_Restrictions_Section --
      --------------------------------------

      procedure Read_System_Restrictions_Section
        (System : in out RTG.System.System_Descriptor)
      is
         type Components is (None, No_Finalization);

         Component : Components := None;
         Key       : VSS.Strings.Virtual_String;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "No_Finalization" then
                     Component := No_Finalization;

                  else
                     RTG.Diagnostics.Warning
                       ("`{}` is unknown system restrictions parameter",
                        Key);
                  end if;

               when Boolean_Value =>
                  case Component is
                     when No_Finalization =>
                        System.Set_No_Finalization (Reader.Boolean_Value);

                     when others =>
                        RTG.Diagnostics.Warning
                          ("`{}` runtime system restrictions is not boolean",
                        Key);
                        Reader.Skip_Current_Object;
                  end case;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_System_Restrictions_Section;

      -------------------------
      -- Read_System_Section --
      -------------------------

      procedure Read_System_Section
        (System : in out RTG.System.System_Descriptor)
      is
         type Components is (None, Restrictions);

         Component : Components := None;
         Key       : VSS.Strings.Virtual_String;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "restrictions" then
                     Component := Restrictions;

                  else
                     RTG.Diagnostics.Warning
                       ("`{}` is unknown system configuration parameter",
                        Key);
                  end if;

               when Start_Object =>
                  case Component is
                     when Restrictions =>
                        Read_System_Restrictions_Section (System);

                     when others =>
                        RTG.Diagnostics.Warning
                          ("`{}` system configuration parameter is not object",
                        Key);
                        Reader.Skip_Current_Object;
                  end case;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_System_Section;

      ------------------
      -- Read_Tasking --
      ------------------

      procedure Read_Tasking is

         type Parameter_Kind is (Kernel, Files);

         Not_An_Object : constant
           VSS.Strings.Templates.Virtual_String_Template :=
             "`{}` tasking configuration parameter is not an object";

         Parameter : Parameter_Kind;
         Key       : VSS.Strings.Virtual_String;

      begin
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key = "files" then
                     Parameter := Files;

                  elsif Key = "kernel" then
                     Parameter := Kernel;

                  else
                     RTG.Diagnostics.Warning
                       ("`{}` is unknown tasking configuration parameter",
                        Key);
                  end if;

               when String_Value =>
                  case Parameter is
                     when Kernel =>
                        Tasking.Kernel := Reader.String_Value;

                     when others =>
                        RTG.Diagnostics.Warning (Not_An_Object, Key);
                  end case;

               when Start_Object =>
                  case Parameter is
                     when Files =>
                        Read_Files_Section (Tasking.Files);

                     when others =>
                        RTG.Diagnostics.Warning (Not_An_Object, Key);
                        Reader.Skip_Current_Object;
                  end case;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Tasking;

      -----------------
      -- Read_Values --
      -----------------

      procedure Read_Values
        (Values : in out VSS.String_Vectors.Virtual_String_Vector) is
      begin
         loop
            case Reader.Read_Next is
               when String_Value =>
                  Values.Append (Reader.String_Value);

               when End_Array =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Values;

   begin
      Runtime.Descriptor_Directory := File.Dir;

      Input.Open
        (VSS.Strings.Conversions.To_Virtual_String (File.Display_Full_Name));
      Reader.Set_Stream (Input'Unchecked_Access);

      loop
         case Reader.Read_Next is
            when Start_Document =>
               null;

            when End_Document =>
               exit;

            when Start_Object =>
               Read_Configuration;

            when others =>
               raise Program_Error with Reader.Element_Kind'Img;
         end case;
      end loop;

      Input.Close;
   end Read;

end RTG.Runtime_Reader;
