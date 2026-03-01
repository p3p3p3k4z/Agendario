import re

d = 'lib/widgets/habit_card.dart'
with open(d, 'r') as f: c = f.read()
c = c.replace('_habitColor()', '_habitColor(BuildContext context)')
with open(d, 'w') as f: f.write(c)

d = 'lib/widgets/day_entry_tile.dart'
with open(d, 'r') as f: c = f.read()
c = c.replace('_cardColor()', '_cardColor(BuildContext context)')
c = c.replace('_buildLeading()', '_buildLeading(BuildContext context)')
c = c.replace('_buildContent()', '_buildContent(BuildContext context)')
with open(d, 'w') as f: f.write(c)

d = 'lib/widgets/calendar_cell_builder.dart'
with open(d, 'r') as f: c = f.read()
c = c.replace('_buildDots()', '_buildDots(BuildContext context)')
c = c.replace('_dotColor(EntryType type)', '_dotColor(BuildContext context, EntryType type)')
c = c.replace('_dotColor(type)', '_dotColor(context, type)')
with open(d, 'w') as f: f.write(c)

d = 'lib/screens/event_editor_screen.dart'
with open(d, 'r') as f: c = f.read()
c = c.replace('static const List<Color> _colorOptions = [', 'List<Color> get _colorOptions => [')
with open(d, 'w') as f: f.write(c)
