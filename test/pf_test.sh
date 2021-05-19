#!/bin/sh
. shmod
import github.com/sageify/shert@v0.0.1 shert.sh

shert_equals './pf -b "Hello World"' '[Hello World]'
shert_equals "./pf -b -w" '[Hello World]' 
assert_equals '[Hello World]' "$(./pf -bw)"
assert_equals '[Hello][World]' "$(./pf -bs)"
assert_equals '[Hello][World]' "$(./pf -b "-s")"

assert_equals '[-s Yall]' "$(./pf -b "-s Yall")"
assert_equals '[Hello][World][Yall]' "$(./pf -bs Yall)"

assert_equals '[Hello][World][Hello World]' "$(./pf -b --lines)"

assert_equals '[edge][case]' "$(./pf -b --dang)"
assert_equals '[edge][case]' "$(./pf -b "--dang")"

assert_equals '[edge][case][edge][case]' "$(./pf -b --dang edge case)"
assert_equals '[--dang edge case]' "$(./pf -b "--dang edge case")"

shert_empty './pf -b --dangcase 2>/dev/null'
shert_fail './pf -b --dangcase'

shert_equals './pf -b --dangcase ""' '[edge][case=]'
shert_equals './pf -b --dangcase edge' '[edge][case=edge]'

assert_equals '[edge][case=edge][case]' "$(./pf -b --dangcase edge case)"
assert_equals '[--dangcase edge case]' "$(./pf -b "--dangcase edge case")"
shert_equals './pf -b --dangcase "edge case"' '[edge][case=edge case]'

shert_fail './pf -b --dangword'

assert_equals '[edge case=]' "$(./pf -b --dangword "")"
shert_equals './pf -b --dangword edge case' '[edge case=edge][case]'
shert_equals './pf -b --dangquoted edge case' '[edge case=edge][case]'

assert_equals '[   ]' "$(./pf -b --spaces)"
assert_equals '[Hello `World]' "$(./pf -b -t)"

assert_equals '[edge][case][--ignore-rest][--dang][--dang]' "$(./pf -b --dang --ignore-rest --dang --dang)"
assert_equals '[edge][case][--ignore-next][--dang][edge][case]' "$(./pf -b --dang --ignore-next --dang --dang)"

assert_equals '[all]' "$(./pf -b --all)"

shert_fail './pf -b --e1'

assert_equals '[-xy]' "$(./pf -b -xy)"

shert_equals './pf -b --quoted' '[Hello World][Goodbye World]'
shert_equals './pf -b --dollar' '[$HOME]'

shert_equals './pf -b --prepend Hi There' '[Hi][Hello][World][There]'
shert_equals './pf -b --prepend "Hi There"' '[Hi There][Hello][World]'
