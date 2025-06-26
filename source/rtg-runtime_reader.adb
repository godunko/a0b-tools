--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with VSS.JSON.Pull_Readers.JSON5;
with VSS.JSON.Streams;
with VSS.Strings.Conversions;
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
      Scenarios : out RTG.GNAT_RTS_Sources.Scenario_Maps.Map)
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

               when Start_Object =>
                  if Key = "runtime" then
                     Read_Runtime;

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

      ------------------
      -- Read_Runtime --
      ------------------

      procedure Read_Runtime is
         Key    : VSS.Strings.Virtual_String;
         Values : VSS.String_Vectors.Virtual_String_Vector;

         procedure Read_Values
           with Pre  => Reader.Element_Kind = Start_Array,
                Post => Reader.Element_Kind = End_Array;

         -----------------
         -- Read_Values --
         -----------------

         procedure Read_Values is
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
         loop
            case Reader.Read_Next is
               when Key_Name =>
                  Key := Reader.Key_Name;

                  if Key not in "common_required_switches" then
                     RTG.Diagnostics.Warning
                       ("`{}` is unknown runtime configuration parameter",
                        Key);
                  end if;

               --  when String_Value =>
               --     Scenarios.Insert (Key, Reader.String_Value);
               --
               when Start_Array =>
                  Read_Values;

                  if Key = "common_required_switches" then
                     Runtime.Common_Required_Switches := Values;

                  else
                     RTG.Diagnostics.Warning
                       ("`{}` runtime configuration parameter is not an array",
                        Key);
                  end if;

                  Values.Clear;

               when End_Object =>
                  exit;

               when others =>
                  raise Program_Error with Reader.Element_Kind'Img;
            end case;
         end loop;
      end Read_Runtime;

   begin
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
