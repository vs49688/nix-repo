--
-- Embedded Nimrod Modulefile, Lmod version
--
local nimrod_version    = "@nimrod_version@"
local base_path         = "@root_dir@"
local nimrod_home       = "@nimrod_home@"
local java_home         = "@java_home@"
local qpid_home         = "@qpid_home@"

whatis("Name: Embedded Nimrod")
whatis("Version: "..nimrod_version)
whatis("URL: https://rcc.uq.edu.au/nimrod")

help([[
To exec a #NIM script:
	nimexec /path/to/script

To run a planfile:
    nimrun /path/to/planfile

To validate a planfile:
    nimrod compile --no-out /path/to/planfile
]])

setenv("JAVA_HOME", java_home)
setenv("NIMROD_HOME", nimrod_home)
setenv("QPID_HOME", qpid_home)

prepend_path("PATH", pathJoin(java_home, "bin"))
prepend_path("PATH", pathJoin(base_path, "bin"))
prepend_path("PATH", pathJoin(nimrod_home, "bin"))

setenv("OMP_NUM_THREADS", os.getenv("OMP_NUM_THREADS") or "1")

