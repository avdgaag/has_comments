module AGW
  module HasComments
    module Utils
      #
      # RFC822 Email Address Regex
      # --------------------------
      #
      # Originally written by Cal Henderson
      # c.f. http://iamcal.com/publish/articles/php/parsing_email/
      #
      # Translated to Ruby by Tim Fletcher, with changes suggested by Dan Kubb.
      #
      # Licensed under a Creative Commons Attribution-ShareAlike 2.5 License
      # http://creativecommons.org/licenses/by-sa/2.5/
      #
      def self.email
        qtext          = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
        dtext          = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
        atom           = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' + '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
        quoted_pair    = '\\x5c[\\x00-\\x7f]'
        domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
        quoted_string  = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
        domain_ref     = atom
        sub_domain     = "(?:#{domain_ref}|#{domain_literal})"
        word           = "(?:#{atom}|#{quoted_string})"
        domain         = "#{sub_domain}(?:\\x2e#{sub_domain})*"
        local_part     = "#{word}(?:\\x2e#{word})*"
        addr_spec      = "#{local_part}\\x40#{domain}"
        pattern        = /\A#{addr_spec}\z/
      end

      # Immediatly return a standard regular expression for matching valid URLs.
      def self.url
        /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
      end
    end
  end
end