--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Containers.Vectors;

with Input_Sources.File;

with VSS.IRIs;
with VSS.Strings.Conversions;
with VSS.XML.Attributes;
with VSS.XML.Content_Handlers;
with VSS.XML.XmlAda_Readers;

package body RTG.SVD_Reader is

   type States is
     (Initial,
      Interrupt,
      Interrupt_Name,
      Interrupt_Description,
      Interrupt_Value);

   type State_Record is record
      State : States;
   end record;

   package State_Vectors is
     new Ada.Containers.Vectors (Positive, State_Record);

   type SVD_Parser is limited new VSS.XML.Content_Handlers.SAX_Content_Handler
   with record
      State      : State_Record;
      Stack      : State_Vectors.Vector;
      Interrupt  : RTG.Interrupts.Interrupt_Information;

      Interrupts : RTG.Interrupts.Interrupt_Information_Vectors.Vector;
   end record;

   --  procedure Set_Document_Locator
   --    (Self    : in out SAX_Content_Handler;
   --     Locator : VSS.XML.Locators.SAX_Locator_Access) is null;

   overriding procedure Start_Document
     (Self    : in out SVD_Parser;
      Success : in out Boolean);

   overriding procedure End_Document
     (Self    : in out SVD_Parser;
      Success : in out Boolean);

   --  procedure Start_Prefix_Mapping
   --    (Self    : in out SAX_Content_Handler;
   --     Prefix  : VSS.Strings.Virtual_String;
   --     URI     : VSS.IRIs.IRI;
   --     Success : in out Boolean) is null;
   --
   --  procedure End_Prefix_Mapping
   --    (Self    : in out SAX_Content_Handler;
   --     Prefix  : VSS.Strings.Virtual_String;
   --     Success : in out Boolean) is null;

   overriding procedure Start_Element
     (Self       : in out SVD_Parser;
      URI        : VSS.IRIs.IRI;
      Name       : VSS.Strings.Virtual_String;
      Attributes : VSS.XML.Attributes.XML_Attributes'Class;
      Success    : in out Boolean);

   overriding procedure End_Element
     (Self    : in out SVD_Parser;
      URI     : VSS.IRIs.IRI;
      Name    : VSS.Strings.Virtual_String;
      Success : in out Boolean);

   overriding procedure Characters
     (Self    : in out SVD_Parser;
      Text    : VSS.Strings.Virtual_String;
      Success : in out Boolean);

   --  procedure Ignorable_Whitespace
   --    (Self    : in out SAX_Content_Handler;
   --     Text    : VSS.Strings.Virtual_String;
   --     Success : in out Boolean) is null;
   --
   --  procedure Processing_Instruction
   --    (Self    : in out SAX_Content_Handler;
   --     Target  : VSS.Strings.Virtual_String;
   --     Data    : VSS.Strings.Virtual_String;
   --     Success : in out Boolean) is null;
   --
   --  procedure Skipped_Entity
   --    (Self    : in out SAX_Content_Handler;
   --     Name    : VSS.Strings.Virtual_String;
   --     Success : in out Boolean) is null;

----------------
-- Characters --
----------------

   overriding procedure Characters
     (Self    : in out SVD_Parser;
      Text    : VSS.Strings.Virtual_String;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      case Self.State.State is
         when Initial | Interrupt =>
            null;

         when Interrupt_Name =>
            Self.Interrupt.Name := Text;

         when Interrupt_Description =>
            Self.Interrupt.Description := Text;

         when Interrupt_Value =>
            Self.Interrupt.Value :=
              Integer'Wide_Wide_Value
                (VSS.Strings.Conversions.To_Wide_Wide_String (Text));
      end case;
   end Characters;

   ------------------
   -- End_Document --
   ------------------

   overriding procedure End_Document
     (Self : in out SVD_Parser; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

      function "<"
        (Left  : RTG.Interrupts.Interrupt_Information;
         Right : RTG.Interrupts.Interrupt_Information)
         return Boolean;

      ---------
      -- "<" --
      ---------

      function "<"
        (Left  : RTG.Interrupts.Interrupt_Information;
         Right : RTG.Interrupts.Interrupt_Information)
         return Boolean is
      begin
         return Left.Value < Right.Value;
      end "<";

      package Sorting is
        new RTG.Interrupts.Interrupt_Information_Vectors.Generic_Sorting ("<");

   begin
      Sorting.Sort (Self.Interrupts);
   end End_Document;

   -----------------
   -- End_Element --
   -----------------

   overriding procedure End_Element
     (Self    : in out SVD_Parser;
      URI     : VSS.IRIs.IRI;
      Name    : VSS.Strings.Virtual_String;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      case Self.State.State is
         when Interrupt =>
            Self.Interrupts.Append (Self.Interrupt);

         when others =>
            null;
      end case;

      Self.State := Self.Stack.Last_Element;
      Self.Stack.Delete_Last;
   end End_Element;

   ----------
   -- Read --
   ----------

   procedure Read
     (File       : GNATCOLL.VFS.Virtual_File;
      Interrupts : out RTG.Interrupts.Interrupt_Information_Vectors.Vector)
   is
      Input  : Input_Sources.File.File_Input;
      Reader : VSS.XML.XmlAda_Readers.XmlAda_Reader;
      Parser : aliased SVD_Parser;

   begin
      Reader.Set_Content_Handler (Parser'Unchecked_Access);

      Input_Sources.File.Open (File.Display_Full_Name, Input);
      Reader.Parse (Input);
      Input.Close;

      Interrupts := Parser.Interrupts;
   end Read;

   --------------------
   -- Start_Document --
   --------------------

   overriding procedure Start_Document
     (Self : in out SVD_Parser; Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      Self.State := (State => Initial);
      Self.Stack.Clear;
      Self.Interrupts.Clear;
   end Start_Document;

   -------------------
   -- Start_Element --
   -------------------

   overriding procedure Start_Element
     (Self       : in out SVD_Parser;
      URI        : VSS.IRIs.IRI;
      Name       : VSS.Strings.Virtual_String;
      Attributes : VSS.XML.Attributes.XML_Attributes'Class;
      Success    : in out Boolean)
   is
      pragma Unreferenced (Success);

      use type VSS.Strings.Virtual_String;

   begin
      Self.Stack.Append (Self.State);

      case Self.State.State is
         when Initial =>
            if Name = "interrupt" then
               Self.State := (State => Interrupt);
               Self.Interrupt := (Value => Natural'Last, others => <>);
            end if;

         when Interrupt =>
            if Name = "name" then
               Self.State := (State => Interrupt_Name);

            elsif Name = "description" then
               Self.State := (State => Interrupt_Description);

            elsif Name = "value" then
               Self.State := (State => Interrupt_Value);

            else
               raise Program_Error
                 with VSS.Strings.Conversions.To_UTF_8_String (Name);
            end if;

         when others =>
            raise Program_Error
              with VSS.Strings.Conversions.To_UTF_8_String (Name);
      end case;
   end Start_Element;

end RTG.SVD_Reader;
