module DemoSeeds
  # Original, character-inspired notes; no quotations, health claims or advice.
  THEMES = {
    "client" => [
      "Solved the meal-prep mystery: the missing lid was under the shopping list.",
      "Packed snacks for a journey that turned out to be a very long bus ride.",
      "Tea was plentiful today. Water needs a promotion.",
      "Second breakfast was really just first breakfast arriving in two installments.",
      "The lunch container returned from its expedition to the back of the fridge.",
      "Tried a starship-style packing checklist. Fork, water, lunch: all aboard.",
      "My apple survived the commute. The banana had a more eventful journey.",
      "Weekend plan: a walk, a sandwich, and absolutely no detective work before lunch."
    ],
    "sherlock-holmes" => [
      "Solved the case, forgot lunch. Tomorrow's mystery: where I put the meal-prep containers.",
      "Found crumbs beside the notebook. Strong evidence that breakfast happened.",
      "Set the lunch alarm before opening the case file this time.",
      "The missing container was in my bag all along. A satisfying conclusion.",
      "A walk gave me a fresh angle on the puzzle and a reason to unpack my sandwich.",
      "Shared soup after the case closed. Left the evidence board in the other room."
    ],
    "frodo-baggins" => [
      "Packed an apple for the walk to Mordor. Should probably pack a second apple.",
      "Second breakfast planning now has its own corner of the map.",
      "The road was longer than expected. Glad I wrapped an extra sandwich.",
      "Stopped beside a stream and remembered the water bottle in my pack.",
      "Made a simple supper and let my feet rest while the kettle warmed.",
      "Home-style toast made the unfamiliar campsite feel a little friendlier."
    ],
    "bilbo-baggins" => [
      "An unexpected visitor meant dividing the muffins into smaller, friendlier pieces.",
      "Labeled the second-breakfast shelf. Organization can be an adventure too.",
      "Packed a pocket snack before leaving the garden gate.",
      "A quiet supper and an unfinished map made a pleasant evening."
    ],
    "arthur-dent" => [
      "Packed snacks for an unexpectedly long journey. Also remembered a towel.",
      "The timetable changed again. My sandwich remained reassuringly on schedule.",
      "Found a quiet corner for breakfast between confusing announcements.",
      "Put a water bottle beside the travel bag so it would not be left behind."
    ],
    "dorothy-gale" => [
      "Packed a picnic for the road. The basket is easier to follow than the map.",
      "Stopped for water after a very colorful stretch of walking.",
      "Shared the last pear and wrote down what to pack tomorrow.",
      "A familiar bowl of oats made this unfamiliar morning feel like home."
    ],
    "jean-luc-picard" => [
      "Tea was plentiful today. Water needs a promotion.",
      "Moved lunch ahead of the afternoon briefing. The sandwich appreciated the attention.",
      "Packed fruit for the away trip and brought the empty container home.",
      "A quiet walk after a busy shift was a welcome change of pace.",
      "Refilled the water bottle before opening another report.",
      "Dinner with friends ran longer than planned. The conversation was worth lingering over."
    ]
  }.freeze

  OBSERVATIONS = [
    "Made oats with sliced pear before heading out.",
    "Packed leftover rice and vegetables in the container I finally found.",
    "Refilled my water bottle before the afternoon errands.",
    "Took a short walk while waiting for the laundry.",
    "Turned the screens off early and read a few pages before bed.",
    "Wrote a shopping list after checking what was already in the kitchen.",
    "Tried crunchy chickpeas in my lunch box. They traveled surprisingly well.",
    "A busy morning became a quiet lunch by the window.",
    "Put tomorrow's breakfast things on the counter tonight.",
    "Shared a pot of soup and saved a portion for another day.",
    "A rainy evening called for indoor stretching and a warm supper.",
    "Remembered the fork this time. A small but satisfying packing victory."
  ].freeze
  FOLLOW_UPS = [
    "The earlier packing experiment made leaving the house less rushed.",
    "I wrote down what worked so I can find the idea again.",
    "Tomorrow I want to leave more time to sit down and enjoy it.",
    "The notebook is becoming a useful collection of small discoveries.",
    "Kept the plan simple after a busier week than expected.",
    "A friend suggested a different container; I might try it next time.",
    "The afternoon felt less hurried with one errand already done.",
    "Left a note on the fridge so tomorrow's version of me remembers.",
    "There was room for a little improvisation, which made the day fun."
  ].freeze

  def self.journal_text(login, index, client_index)
    themes = THEMES.fetch(login, [])
    observation = if index.even? && themes.any?
      themes[(index / 2) % themes.size]
    else
      OBSERVATIONS[(index + client_index) % OBSERVATIONS.size]
    end
    follow_up = FOLLOW_UPS[(index / 3 + client_index) % FOLLOW_UPS.size]
    separator = index % 5 == 0 ? "\n\n" : " "
    # Include occasional short entries as well as longer/multiline reflections.
    index % 7 == 0 ? observation : "#{observation}#{separator}#{follow_up}"
  end
end
