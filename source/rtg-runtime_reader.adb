--
--  Copyright (C) 2025-2026, Vadim Godunko <vgodunko@gmail.com>
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
      use type GNATCOLL.VFS.Virtual_File;
      use all type VSS.JSON.Streams.JSON_Stream_Element_Kind;
      use type VSS.Strings.Virtual_String;

      Input  : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader : VSS.JSON.Pull_Readers.JSON5.JSON5_Pull_Reader;

      --  Value readers enter on the first token of a value and leave on
      --  the token immediately following it, including for empty containers.

      procedure Next;

      procedure Expect
        (Kind    : VSS.JSON.Streams.JSON_Stream_Element_Kind;
         Context : VSS.Strings.Virtual_String);

      function Read_Key return VSS.Strings.Virtual_String;

      procedure Skip_Value;

      procedure Skip_Unknown (Key : VSS.Strings.Virtual_String);

      function Read_String
        (Context : VSS.Strings.Virtual_String)
         return VSS.Strings.Virtual_String;

      function Read_Boolean
        (Context : VSS.Strings.Virtual_String) return Boolean;

      function Read_Integer
        (Context : VSS.Strings.Virtual_String) return Integer;

      procedure Read_Configuration;

      procedure Read_Runtime;

      procedure Read_Tasking;

      procedure Read_Scenarios;

      procedure Read_Files_Section
        (Files   : in out RTG.File_Descriptor_Vectors.Vector;
         Context : VSS.Strings.Virtual_String);

      procedure Read_System_Section;

      procedure Read_System_Parameters_Section;

      procedure Read_System_Restrictions_Section;

      procedure Read_Values
        (Values  : in out VSS.String_Vectors.Virtual_String_Vector;
         Context : VSS.Strings.Virtual_String);

      procedure Parse_Memory_Descriptor
        (Values     : VSS.String_Vectors.Virtual_String_Vector;
         Descriptor : in out RTG.Memory_Descriptor);

      procedure Process_Include (Path : VSS.Strings.Virtual_String);

      ----------
      -- Next --
      ----------

      procedure Next is
         use all type VSS.JSON.Pull_Readers.JSON_Reader_Error;

      begin
         loop
            begin
               Reader.Read_Next;

            exception
               when Program_Error =>
                  --  Some malformed JSON5 constructs raise directly in VSS.

                  RTG.Diagnostics.Error (File, "invalid JSON input");
            end;

            if Input.Has_Error then
               RTG.Diagnostics.Error (File, Input.Error_Message);
            end if;

            --  JSON5 can retain Premature_End_Of_Document after emitting
            --  a valid final token. Invalid tokens still fail immediately.

            if Reader.Element_Kind = Invalid
              or Reader.Error in Not_Valid | Custom_Error
            then
               if Reader.Error_Message.Is_Empty then
                  RTG.Diagnostics.Error (File, "unexpected end of document");

               else
                  RTG.Diagnostics.Error (File, Reader.Error_Message);
               end if;
            end if;

            exit when Reader.Element_Kind /= Comment;
         end loop;
      end Next;

      ------------
      -- Expect --
      ------------

      procedure Expect
        (Kind    : VSS.JSON.Streams.JSON_Stream_Element_Kind;
         Context : VSS.Strings.Virtual_String)
      is
         Template : constant VSS.Strings.Templates.Virtual_String_Template :=
           "`{}`: expected {}, got {}";

      begin
         if Reader.Element_Kind /= Kind then
            RTG.Diagnostics.Error
              (File,
               Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Context),
                  VSS.Strings.Formatters.Strings.Image
                    (VSS.Strings.Conversions.To_Virtual_String (Kind'Image)),
                  VSS.Strings.Formatters.Strings.Image
                    (VSS.Strings.Conversions.To_Virtual_String
                       (Reader.Element_Kind'Image))));
         end if;
      end Expect;

      --------------
      -- Read_Key --
      --------------

      function Read_Key return VSS.Strings.Virtual_String is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Key_Name, "object member");
         Key := Reader.Key_Name;
         Next;

         return Key;
      end Read_Key;

      ----------------
      -- Skip_Value --
      ----------------

      procedure Skip_Value is
         Depth : Natural := 0;

      begin
         case Reader.Element_Kind is
            when Start_Object | Start_Array =>
               Depth := 1;

            when String_Value | Boolean_Value | Number_Value | Null_Value =>
               null;

            when others =>
               RTG.Diagnostics.Error (File, "expected a JSON value");
         end case;

         Next;

         while Depth /= 0 loop
            case Reader.Element_Kind is
               when Start_Object | Start_Array =>
                  Depth := @ + 1;

               when End_Object | End_Array =>
                  Depth := @ - 1;

               when Key_Name | String_Value | Boolean_Value
                 | Number_Value | Null_Value =>
                  null;

               when others =>
                  RTG.Diagnostics.Error (File, "incomplete JSON value");
            end case;

            Next;
         end loop;
      end Skip_Value;

      ------------------
      -- Skip_Unknown --
      ------------------

      procedure Skip_Unknown (Key : VSS.Strings.Virtual_String) is
         Template : constant VSS.Strings.Templates.Virtual_String_Template :=
           "configuration parameter `{}` is unknown";

      begin
         RTG.Diagnostics.Warning
           (File,
            Template.Format (VSS.Strings.Formatters.Strings.Image (Key)));
         Skip_Value;
      end Skip_Unknown;

      -----------------
      -- Read_String --
      -----------------

      function Read_String
        (Context : VSS.Strings.Virtual_String)
         return VSS.Strings.Virtual_String
      is
         Value : VSS.Strings.Virtual_String;

      begin
         Expect (String_Value, Context);
         Value := Reader.String_Value;
         Next;

         return Value;
      end Read_String;

      ------------------
      -- Read_Boolean --
      ------------------

      function Read_Boolean
        (Context : VSS.Strings.Virtual_String) return Boolean
      is
         Value : Boolean;

      begin
         Expect (Boolean_Value, Context);
         Value := Reader.Boolean_Value;
         Next;

         return Value;
      end Read_Boolean;

      ------------------
      -- Read_Integer --
      ------------------

      function Read_Integer
        (Context : VSS.Strings.Virtual_String) return Integer
      is
         use type VSS.JSON.JSON_Number_Kind;

         Value : Integer;
         Template : constant VSS.Strings.Templates.Virtual_String_Template :=
           "`{}`: expected an integer in range of Standard.Integer";

      begin
         Expect (Number_Value, Context);

         if Reader.Number_Value.Kind /= VSS.JSON.JSON_Integer then
            RTG.Diagnostics.Error
              (File,
               Template.Format
                 (VSS.Strings.Formatters.Strings.Image (Context)));
         end if;

         begin
            Value := Integer (Reader.Number_Value.Integer_Value);

         exception
            when Constraint_Error =>
               RTG.Diagnostics.Error
                 (File,
                  Template.Format
                    (VSS.Strings.Formatters.Strings.Image (Context)));
         end;

         Next;

         return Value;
      end Read_Integer;

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
            RTG.Diagnostics.Error (File, "memory must have two components");
         end if;

         --  Convert address

         Value := Values (1);

         if not Value.Starts_With ("0x") then
            RTG.Diagnostics.Error (File, "memory address must start with 0x");
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
            RTG.Diagnostics.Error (File, "memory size must use DT_SIZE_K");
         end if;

      exception
         when Constraint_Error =>
            RTG.Diagnostics.Error (File, "invalid memory address or size");
      end Parse_Memory_Descriptor;

      ---------------------
      -- Process_Include --
      ---------------------

      procedure Process_Include (Path : VSS.Strings.Virtual_String) is
         Include_File : constant GNATCOLL.VFS.Virtual_File :=
           GNATCOLL.VFS.Create_From_Base
             (GNATCOLL.VFS.Filesystem_String
                (VSS.Strings.Conversions.To_UTF_8_String (Path)),
              File.Dir_Name);

      begin
         Read (Include_File, Runtime, Tasking, Startup, System, Scenarios);
      end Process_Include;

      ------------------------
      -- Read_Configuration --
      ------------------------

      procedure Read_Configuration is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "configuration");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;

            if Key = "include" then
               Process_Include (Read_String (Key));

            elsif Key = "runtime" then
               Read_Runtime;

            elsif Key = "tasking" then
               Read_Tasking;

            elsif Key = "scenarios" then
               Read_Scenarios;

            elsif Key = "dt:/chosen/a0b,flash:reg"
              or Key = "dt:/chosen/a0b,sram:reg"
            then
               declare
                  Values : VSS.String_Vectors.Virtual_String_Vector;

               begin
                  Read_Values (Values, Key);

                  if Key = "dt:/chosen/a0b,flash:reg" then
                     Parse_Memory_Descriptor (Values, Startup.Flash);

                  else
                     Parse_Memory_Descriptor (Values, Startup.SRAM);
                  end if;
               end;

            elsif Reader.Element_Kind = String_Value then
               --  Preserve legacy root scenario and device-tree string values.
               Scenarios.Insert (Key, Read_String (Key));

            else
               Skip_Unknown (Key);
            end if;
         end loop;

         Next;
      end Read_Configuration;

      ------------------
      -- Read_Runtime --
      ------------------

      procedure Read_Runtime is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "runtime");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;

            if Key = "common_required_switches" then
               Read_Values (Runtime.Common_Required_Switches, Key);

            elsif Key = "languages" then
               Read_Values (Runtime.Languages, Key);

            elsif Key = "linker_required_switches" then
               Read_Values (Runtime.Linker_Required_Switches, Key);

            elsif Key = "files" then
               Read_Files_Section (Runtime.Runtime_Files, Key);

            elsif Key = "system" then
               Read_System_Section;

            else
               Skip_Unknown (Key);
            end if;
         end loop;

         Next;
      end Read_Runtime;

      ------------------
      -- Read_Tasking --
      ------------------

      procedure Read_Tasking is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "tasking");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;

            if Key = "kernel" then
               Tasking.Kernel := Read_String (Key);

            elsif Key = "files" then
               Read_Files_Section (Tasking.Files, Key);

            else
               Skip_Unknown (Key);
            end if;
         end loop;

         Next;
      end Read_Tasking;

      -------------------------
      -- Read_System_Section --
      -------------------------

      procedure Read_System_Section is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "system");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;

            if Key = "parameters" then
               Read_System_Parameters_Section;

            elsif Key = "restrictions" then
               Read_System_Restrictions_Section;

            elsif Key = "priority_values" then
               System.Priorities.Priority_Values := Read_Integer (Key);

            elsif Key = "interrupt_priority_values" then
               System.Priorities.Interrupt_Priority_Values :=
                 Read_Integer (Key);

            else
               Skip_Unknown (Key);
            end if;
         end loop;

         Next;
      end Read_System_Section;

      ------------------------------------
      -- Read_System_Parameters_Section --
      ------------------------------------

      procedure Read_System_Parameters_Section is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "parameters");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;

            if Key = "Preallocated_Stacks" then
               System.Set_Preallocated_Stacks (Read_Boolean (Key));

            elsif Key = "Suppress_Standard_Library" then
               System.Set_Suppress_Standard_Library (Read_Boolean (Key));

            else
               Skip_Unknown (Key);
            end if;
         end loop;

         Next;
      end Read_System_Parameters_Section;

      --------------------------------------
      -- Read_System_Restrictions_Section --
      --------------------------------------

      procedure Read_System_Restrictions_Section is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "restrictions");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;

            if Key = "No_Exception_Propagation" then
               System.Set_No_Exception_Propagation (Read_Boolean (Key));

            elsif Key = "No_Finalization" then
               System.Set_No_Finalization (Read_Boolean (Key));

            elsif Key = "No_Implicit_Dynamic_Code" then
               System.Set_No_Implicit_Dynamic_Code (Read_Boolean (Key));

            else
               Skip_Unknown (Key);
            end if;
         end loop;

         Next;
      end Read_System_Restrictions_Section;

      --------------------
      -- Read_Scenarios --
      --------------------

      procedure Read_Scenarios is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, "scenarios");
         Next;

         while Reader.Element_Kind /= End_Object loop
            Key := Read_Key;
            Scenarios.Insert (Key, Read_String (Key));
         end loop;

         Next;
      end Read_Scenarios;

      ------------------------
      -- Read_Files_Section --
      ------------------------

      procedure Read_Files_Section
        (Files   : in out RTG.File_Descriptor_Vectors.Vector;
         Context : VSS.Strings.Virtual_String)
      is
         Key : VSS.Strings.Virtual_String;

      begin
         Expect (Start_Object, Context);
         Next;

         while Reader.Element_Kind /= End_Object loop
            declare
               Information : RTG.File_Descriptor;

            begin
               Information.File := Read_Key;
               Expect (Start_Object, Information.File);
               Next;

               while Reader.Element_Kind /= End_Object loop
                  Key := Read_Key;

                  if Key = "crate" then
                     Information.Crate := Read_String (Key);

                  elsif Key = "path" then
                     Information.Path := Read_String (Key);

                  else
                     Skip_Unknown (Key);
                  end if;
               end loop;

               Next;
               Files.Append (Information);
            end;
         end loop;

         Next;
      end Read_Files_Section;

      -----------------
      -- Read_Values --
      -----------------

      procedure Read_Values
        (Values  : in out VSS.String_Vectors.Virtual_String_Vector;
         Context : VSS.Strings.Virtual_String) is
      begin
         Expect (Start_Array, Context);
         Next;

         while Reader.Element_Kind /= End_Array loop
            Values.Append (Read_String (Context));
         end loop;

         Next;
      end Read_Values;

   begin
      if Runtime.Descriptor_Directory = GNATCOLL.VFS.No_File then
         --  Use the directory of the first runtime descriptor processed.

         Runtime.Descriptor_Directory := File.Dir;
      end if;

      Input.Open
        (VSS.Strings.Conversions.To_Virtual_String (File.Display_Full_Name));

      if Input.Has_Error then
         RTG.Diagnostics.Error (File, Input.Error_Message);
      end if;

      Reader.Set_Stream (Input'Unchecked_Access);
      Next;
      Expect (Start_Document, "document");
      Next;
      Read_Configuration;
      Expect (End_Document, "document");
      Input.Close;

   exception
      when others =>
         Input.Close;
         raise;
   end Read;

end RTG.Runtime_Reader;
