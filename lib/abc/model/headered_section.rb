module ABC

  # Base class for Tunebook and Tune.
  #
  # (ie, abc sections that might have a header)

  class HeaderedSection

    # Creates a section with certain children.
    def initialize(children)
      @children = children
    end

    # Returns the section's children.
    # +args+:: Any number of class types. If supplied, only children that pass
    #          <code>is_one_of?(*args)</code> are returned.
    def children(*args)
      args.count == 0 ? @children : @children.select { |it| it.is_one_of?(*args) }
    end

    # _Header_ the header for this section
    def header
      @header ||= children(Header).last || Header.new
    end

    def master_node=(node)
      header.master_header = node.header
    end
    
    # _string_ Value of the A: header.
    def area
      header.value_replace_master(:area)
    end

    # _string_ Value of the B: header.
    def book
      header.value_replace_master(:book)
    end

    # _string_ Value of the C: header.
    def composer
      header.value_replace_master(:composer)
    end

    # _string_ Value of the D: header.
    def discography
      header.value_replace_master(:discography)
    end
    alias_method :disc, :discography

    # _string_ Value of the F: header.
    def file_url
      header.value_replace_master(:file_url)
    end
    alias_method :url, :file_url

    # _string_ Value of the G: header.
    def group
      header.value_replace_master(:group)
    end

    # _string_ Value of the H: header.
    def history
      header.value_replace_master(:history)
    end

    # _Meter_ Meter specified by the M: header, or free meter if no such header.
    def meter
      @meter ||= header.last_value(:meter) || Meter.new(:free)
    end

    # _string_ Value of the N: header. Not to be confused with Tune#notes.
    def notations
      header.value_replace_master(:notations)
    end

    # _string_ Value of the O: header.
    def origin
      header.value_replace_master(:origin)
    end

   # _string_ Value of the R: header.
    def rhythm
      header.value_replace_master(:rhythm)
    end

   # _string_ Value of the S: header.
    def source
      header.value_replace_master(:source)
    end

   # _string_ Value of the T: header.
    def title
      header.value_replace_master(:title)
    end

   # _string_ Value of the Z: header.
    def transcription
      header.value_replace_master(:transcription)
    end

    # <em>{string=>value}</em> Values for all instruction fields in the header.
    # In the hash that's returned, instruction directives are mapped to field
    # values, eg <code>{"decoration"=>"+"}</code> for the instruction field
    # <code>I:decoration +</code>.
    def instructions
      @instructions ||= header.fields(:instruction).inject({}) do |result, field|
        result.merge!(field.name => field.value)
      end
    end

    # _Array_ Values of selected instruction fields in the header.
    #   fragment = "%%MIDI voice V1 instrument=59\n%%MIDI voice V2 instrument=60"
    #   tune = parser.parse_fragment fragment
    #   tune.directive_values("MIDI", "voice")[1].instrument.should == 60
    def directive_values(directive, subdirective=nil)
      d,s = directive, subdirective
      if s
        header.fields(:instruction).inject([]) do |result, field|
          result << field.value if field.directive == d && subdirective = s
        end
      else
        header.fields(:instruction).inject([]) do |result, field|
          result << field.value if field.directive == d
        end
      end
    end

    # <em>{string=>string}</em> Macros defined for this section.
    def macros
      @macros ||= header.fields(:macro).inject({}) do |result, field|
        result.merge!(field.value)
      end
    end

  end
end
