
pragma Ada_2022;

with A0B.Types;

procedure Main is
   use type A0B.Types.Unsigned_32;

   function F return String;

   function F return String is ("def");

   Count : A0B.Types.Unsigned_32 := 0;
   S     : String := "abc" & F & A0B.Types.Unsigned_32'Image (Count);

begin
   for J in 1 .. 1_000 loop
      Count := @ + 1;
   end loop;
end Main;
