package require Tclx
package require Pgtcl

proc dbconnect {DB} {
	if {[catch {set db [pg_connect -connlist [array get ::$DB]]} result] == 1} {
		puts "Unable to connect to database: $result"

	} else {
		return $db
	}
}

proc dbdisconnect {} {
	global db
	if {[info exists db]} {
		catch {pg_disconnect $db}
	}
}

proc sql_exec {conn sql} {
    set result [pg_exec $conn $sql]
    set status [pg_result $result -status]
	set start  [clock microseconds]

    if {[string match "PGRES_*_OK" $status]} {
        set success 1
    } else {
        # errordisplay_add "$status running code:<div class=\"debug_code\">$sql</div>Returned:<div class=\"debug_code\">[pg_result $result -error]</div>"
		puts "<code>SQL ERROR:<br />$status<br />$sql<br />[pg_result $result -error]</code>"
        set success 0
    }

	pg_result $result -clear

	set duration [expr [clock microseconds] - $start]

	# puts "<!-- $sql duration $duration -->"
	return $success
}

proc sql_insert_from_array {table arrvar {idvar ""}} {
	upvar 1 $arrvar arr

	set fname [list]
	set fdata [list]

	foreach f [array names arr] {
		lappend fname $f
		lappend fdata [pg_quote $arr($f)]
	}

	set sql "INSERT INTO $table ([join $fname ","]) VALUES ([join $fdata ","])"
	if {$idvar != ""} {
		append sql " RETURNING $idvar as id"
	} else {
		append sql " RETURNING 1 as id"
	}

	set success 0
	pg_select $::db $sql buf {
		return $buf(id)
	}

	return $success
}

proc load_config {} {
	unset -nocomplain ::config
	array set ::config {}

	pg_select $::db "SELECT item,value FROM config" buf {
		set ::config($buf(item)) $buf(value)
	}
}

package provide ergkeeper 1.0
