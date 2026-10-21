# Fictional manual-demo identities and assigned app credentials, not qualifications
# attributed to real people or canonical characters. Indexes are stable seed keys.
module DemoSeeds
  PROVIDERS = [
    [ "provider", "Morgan Patel", %w[RDN LD] ],
    [ "second-provider", "Taylor Reed", %w[MD] ],
    [ "empty-provider", "Casey Park", %w[CNS] ],
    [ "gregory-house", "Gregory House", %w[MD] ],
    [ "meredith-grey", "Meredith Grey", %w[MD] ],
    [ "john-watson", "John Watson", %w[MD] ],
    [ "beverly-crusher", "Beverly Crusher", %w[MD] ],
    [ "julian-bashir", "Julian Bashir", %w[MD] ],
    [ "michaela-quinn", "Michaela Quinn", %w[MD] ],
    [ "leonard-mccoy", "Leonard McCoy", %w[MD] ],
    [ "dana-scully", "Dana Scully", %w[MD] ],
    [ "miranda-bailey", "Miranda Bailey", %w[MD] ],
    [ "jill-broccoli", "Jill Broccoli", %w[RDN LD CDCES] ],
    [ "sage-rosemary", "Sage Rosemary", %w[RDN LD] ],
    [ "olive-meadows", "Olive Meadows", %w[CNS] ],
    [ "basil-chen", "Basil Chen", %w[RDN LD] ],
    [ "hazel-lentil", "Hazel Lentil", %w[RDN LD CDCES] ],
    [ "ravi-saffron", "Ravi Saffron", %w[CNS] ],
    [ "nora-orchard", "Nora Orchard", %w[RDN LD] ],
    [ "milo-barley", "Milo Barley", %w[RDN LD] ],
    [ "iris-garden", "Iris Garden", %w[CNS] ],
    [ "theo-harvest", "Theo Harvest", %w[RDN LD CDCES] ],
    [ "amara-fig", "Amara Fig", %w[RDN LD] ],
    [ "felix-oats", "Felix Oats", %w[CNS] ],
    [ "leila-grove", "Leila Grove", %w[RDN LD] ],
    [ "owen-sprout", "Owen Sprout", %w[RDN LD CDCES] ],
    [ "pearl-ginger", "Pearl Ginger", %w[CNS] ],
    [ "cedar-bloom", "Cedar Bloom", %w[RDN LD] ],
    [ "poppy-thyme", "Poppy Thyme", %w[CNS] ],
    [ "wren-maple", "Wren Maple", %w[RDN LD] ]
  ].freeze

  CLIENTS = [
    [ "client", "Alex Rivera" ], [ "unrelated-client", "Sam Chen" ],
    [ "empty-client", "Jamie Brooks" ], [ "sherlock-holmes", "Sherlock Holmes" ],
    [ "frodo-baggins", "Frodo Baggins" ], [ "bilbo-baggins", "Bilbo Baggins" ],
    [ "arthur-dent", "Arthur Dent" ], [ "dorothy-gale", "Dorothy Gale" ],
    [ "jean-luc-picard", "Jean-Luc Picard" ], [ "quinn-stillwater", "Quinn Stillwater" ],
    [ "luna-lovegood", "Luna Lovegood" ], [ "pip-willow", "Pip Willow" ],
    [ "samwise-gamgee", "Samwise Gamgee" ], [ "elizabeth-bennet", "Elizabeth Bennet" ],
    [ "anne-shirley", "Anne Shirley" ], [ "jo-march", "Jo March" ],
    [ "alice-liddell", "Alice Liddell" ], [ "winnie-pooh", "Winnie Pooh" ],
    [ "paddington-brown", "Paddington Brown" ], [ "mary-poppins", "Mary Poppins" ],
    [ "peter-pan", "Peter Pan" ], [ "wendy-darling", "Wendy Darling" ],
    [ "tintin", "Tintin" ], [ "nancy-drew", "Nancy Drew" ],
    [ "velma-dinkley", "Velma Dinkley" ], [ "shaggy-rogers", "Shaggy Rogers" ],
    [ "hermione-granger", "Hermione Granger" ], [ "ron-weasley", "Ron Weasley" ],
    [ "leia-organa", "Leia Organa" ], [ "luke-skywalker", "Luke Skywalker" ],
    [ "ahsoka-tano", "Ahsoka Tano" ], [ "rey-skywalker", "Rey Skywalker" ],
    [ "spock", "Spock" ], [ "nyota-uhura", "Nyota Uhura" ],
    [ "kathryn-janeway", "Kathryn Janeway" ], [ "benjamin-sisko", "Benjamin Sisko" ],
    [ "geordi-la-forge", "Geordi La Forge" ], [ "deanna-troi", "Deanna Troi" ],
    [ "miles-obrien", "Miles O'Brien" ], [ "kira-nerys", "Kira Nerys" ]
  ].concat(
    %w[Avery Rowan Emery Finley Jordan Marlow].flat_map do |first|
      %w[Brookfield Calder Dewberry Elmwood Fairhaven Greenleaf Hartley Indigo Juniper Kingsley].map do |last|
        [ "#{first.downcase}-#{last.downcase}", "#{first} #{last}" ]
      end
    end
  ).freeze
end
