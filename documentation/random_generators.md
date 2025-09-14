# Adding support of Random Generators to `light` runtime

Random number generation packages are supproted by `embedded` runtime only, however, it is possible to use them with `light` and `light-tasking` runtimes with one limitation - `Reset` subprogram without initialization value should not be used.

To add support of `Ada.Numerics.Discrete_Random` to runtime, add following lines into `runtime.json` description file:

```
  "runtime":
  {
    "files":
    {
      // Random number generator
      "a-nudira.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-nudira.ads" },
      "a-nudira.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-nudira.adb" },
      "a-stbuut.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-stbuut.ads" },
      "a-stbuut.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-stbuut.adb" },
      "a-sttebu.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-sttebu.ads" },
      "a-sttebu.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-sttebu.adb" },
      "a-stuten.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-stuten.ads" },
      "a-stuten.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-stuten.adb" },
      "a-suenst.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-suenst.ads" },
      "a-suenst.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-suenst.adb" },
      "a-suewst.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-suewst.ads" },
      "a-suewst.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-suewst.adb" },
      "a-suezst.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-suezst.ads" },
      "a-suezst.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/a-suezst.adb" },
      "s-rannum.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/s-rannum.ads" },
      "s-rannum.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/s-rannum.adb" },
      "s-ransee.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/s-ransee.ads" },
      "s-ransee.adb": { "path": "../source/runtime/s-ransee.adb" },
      "s-putima.ads": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/s-putima.ads" },
      "s-putima.adb": { "crate": "bb_runtimes", "path": "gnat_rts_sources/include/rts-sources/full/s-putima.adb" }
    }
  }
```

and add `s-ransee.adb` file to your project

```
--  Dummy version

package body System.Random_Seed is

   --------------
   -- Get_Seed --
   --------------

   function Get_Seed return Interfaces.Unsigned_64 is
   begin
      raise Program_Error;
      return 0;
   end Get_Seed;

end System.Random_Seed;
```
