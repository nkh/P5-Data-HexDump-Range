# NAME

    hdr - Hexadecial Range Dumper, with bitfields, skip ranges, colors and scripting

![screenshot](https://github.com/nkh/P5-Data-HexDump-Range/blob/master/docs/hdr.png)

# USAGE

     $> hdr -r range_definitions file_to_dump
 
     $> hdr file_to_dump -r 'cookie,10,yellow :padding,8 :size,4:data,100' -o ver

    The integer part can of a range definition and offset values can be hexadecimal value starting with *0x*

# RANGE DEFINITION

                      format                          range example

      normal range => integer                         header, 4, bright_blue
      comment      => #                               data section start, # 
      extra header => @                               header, @, red 
      bitfield     => [XInteger][xInteger]bInteger    bitfield, X2x4b4 (offset: X byte, x bit)
      skip range   => XInteger                        boring, X256,, your comment

# OPTIONS

    Options can be given before or after the name of the file to dump.

     range_description|r              file name containing a description
                                      or a string description formated as:
                                          'name,size,color:name,size:name,size:...'

     -                                read data from stdin
 
     dump_original_range_description  dump the un-processed range descriptions
     dump_range_description           dump the processed range descriptions

     offset                           position in the data where to start dumping
     offset_start                     value added to the offset before display
 
     maximum_size                     amount of data to dump
 
     orientation|o                    'horizontal' or 'vertical'
     display_column_names|col         display columns names
     display_ruler|rul                display horizontal ruler
     format|f                         'ANSI' or 'ASCII' or 'HTML' 
     display_command_line             make the command line part of the output
 
     color                            'cycle', 'no_cycle', or 'bw'
     colors                           file containing custom colors
     start_color                      name of the first random color to use
     start_tag/end_tag                text that is output before and after the dump
                                           see L<hdr_examples.pod>
 
     data_width|w                     number of bytes per dump line
 
     offset_format                    'hex' or 'dec' 
     display_offset                   0 == no the offset display
     display_cumulative_offset        0 == no cumulative offset display
     display_zero_size_range          0 == no display of range with size 0
     display_zero_size_range_warning  0 == no warnings about ranges with size 0
     display_comment_range            0 == no comment range display 
 
     display_range_name               1 == display of the range name
     maximum_range_name_size          truncate range name if longer
     display_range_size               1 == prepend the range size to the name
 
     display_hex_dump                 1 == display hexadecimal dump column
     display_hexascii_dump            1 == display vombined HEX and ASCII dump column
     display_dec_dump                 1 == display decimal dump column
     display_ascii_dump               1 == display ASCII dump column
     display_user_information         1 == display user information columns
     maximum_user_information_size    truncate user information if longer
 
     display_bitfields                1 == display bitfields
     display_source                   1 == display source for bitfields 
     maximum_bitfield_source_size     truncate bitfield source name if longer
 
     bit_zero_on_left                 1 == bit index zero is on the left

     h|help                           display this scripts help page
     generate_completion_script|bash  generates a completion script on STDOUT

EXAMPLES

     see *scripts/hdr_examples

EXIT STATUS

Non zero if an error occured.

# INSTALLATION

To install this module type the following:

   perl Build.PL
   ./Build
   ./Build test
   ./Build install

AUTHOR

     Nadim ibn hamouda el Khemir
     CPAN ID: NKH
     mailto: nkh@cpan.org

