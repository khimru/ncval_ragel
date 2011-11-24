#!/usr/bin/python3
# -*- coding: utf-8 -*-
#
"""
Simple parser for one instruction DFA.

Usage: {0} [option...] xmlfile
Options:
  --entry entryname       DFA of interest starts with entryname
  --help                  show this message and exit
  --version               print {0} version number and exit
"""

from __future__ import print_function
from lxml import etree
from os import path
import getopt
import gettext
import sys

_ = gettext.gettext

version = "0.0"

anyfield_begin_actions = ['disp8_operand_begin', 'disp32_operand_begin',
			  'imm8_operand_begin', 'imm16_operand_begin',
			  'imm32_operand_begin', 'imm64_operand_begin',
			  'rel8_operand_begin', 'rel16_operand_begin',
			  'rel32_operand_begin']

anyfield_end_actions = ['disp8_operand_end', 'disp32_operand_end',
			'imm8_operand_end', 'imm16_operand_end',
			'imm32_operand_end', 'imm64_operand_end',
			'rel8_operand_end', 'rel16_operand_end',
			'rel32_operand_end']

def anyfield_action(xmlfile, dfa_tree, action_table_id, anyfield_list):
  """ Returns true if action_table_id includes action from anyfield_list"""
  if action_table_id == 'x':
    return False
  action_table = dfa_tree.xpath('//action_table[@id="'+action_table_id+'"]')
  if len(action_table) != 1:
    raise Exception(_(
      '{0}: XML error in file «{1}» - action_table «{2}» not found').
				 format(program_name, xmlfile, action_table_id))
    return False
  actions = action_table[0].text.split(' ')
  for action_id in actions:
    action = dfa_tree.xpath('//action[@id="'+action_id+'"]')
    if len(action) != 1:
      raise Exception(_(
        '{0}: XML error in file «{1}» - action «{2}» not found').
				       format(program_name, xmlfile, action_id))
      return False
    action_name = action[0].get('name')
    if action_name is None:
      raise Exception(_(
        '{0}: XML error in file «{1}» - name of action «{2}» not found').
				       format(program_name, xmlfile, action_id))
      return False
    if action_name in anyfield_list:
      return True
  return False

def traverse_tree(xmlfile, states, entry,
		  prefix='	.byte ', anyfield=False, separator=''):
  """ Recursively traverse the DFA tree """

  state = states[entry]
  # If it's final entry then we have sequence to print
  if state[1]:
    print(prefix)
  if anyfield:
    if not state[2]:
      raise Exception(_(
	'{0}: XML error in file «{1}» - state «{2}» is not «anyfield»').
					   format(program_name, xmlfile, entry))
    if state[4]:
      traverse_tree(xmlfile, states, state[0][0],
	       '{0}{1}{2:#04x}'.format(prefix, separator, anyfield), False, ',')
    else:
      traverse_tree(xmlfile, states, state[0][0],
       '{0}{1}{2:#04x}'.format(prefix, separator, anyfield), anyfield+0x22, ',')
  else:
    # If we have actions attached then we need to see if one of them is
    # "anyfield" action like disp8 or imm64.  We start with 0x01 in this
    # case and continue with 0x23, etc.
    if state[3]:
      # If it's one-byte anyfield then recursive call is not anyfield.
      if state[4]:
        traverse_tree(xmlfile, states, state[0][0],
		   '{0}{1}{2:#04x}'.format(prefix, separator, 0x01), False, ',')
      else:
        traverse_tree(xmlfile, states, state[0][0],
		    '{0}{1}{2:#04x}'.format(prefix, separator, 0x01), 0x23, ',')
    else:
      for byte in range(0, 256):
        if state[0][byte] != False:
          traverse_tree(xmlfile, states, state[0][byte],
		   '{0}{1}{2:#04x}'.format(prefix, separator, byte), False, ',')

  return 0

def read_trans_lists(xmlfile, dfa_tree):
  """Reads state transtions from ragel XML file and returns python structure"""

  states = []

  xml_states = dfa_tree.xpath('//state')

  for state in xml_states:
    # Ragel always dumps states in order, but better to check that it's still so
    state_id = state.get('id')
    if int(state_id) != len(states):
      raise Exception(_(
	'{0}: error in file «{1}»: state #{2} where #{3} expected').
			   format(program_name, xmlfile, state_id, len(states)))

    # All 256 possible transitions plus the following marks:
    #   Final mark is it's final state.
    #   Any_byte mark if all bytes lead to the same conclusion.
    #   Anyfield_begin mark if anyfield_begin action detected.
    #   Anyfield_end mark if anyfield_end action detected.
    transformations = ([False] * 256,
		       True if state.get('final') else False,
		       False, False, False)

    # Mark available transitions.
    for t in state.getchildren()[0].getchildren():
      trans = t.text.split(' ')
      range_begin = int(trans[0])
      range_end = int(trans[1])+1
      range_full = ((range_begin == 0) and (range_end == 256))
      anyfield_begin = anyfield_action(xmlfile, dfa_tree, trans[3],
							 anyfield_begin_actions)
      anyfield_end = anyfield_action(xmlfile, dfa_tree, trans[3],
							   anyfield_end_actions)
      if (anyfield_begin or anyfield_end) and not (range_full):
        raise Exception(_(
	    '{0}: error in file «{1}»: incorrect anyfiend action in {2}»').
					format(program_name, xmlfile, state_id))
      if range_full:
        transformations = ([False] * 256,
			   True if state.get('final') else False,
			   True, anyfield_begin, anyfield_end)
      for byte in range(range_begin, range_end):
        transformations[0][byte] = int(trans[2])

    states.append(transformations)

  return states

def main(argv):
  """Main program."""

  global program_name
  program_name = path.basename(argv[0])

  entry = None

  # Options processing
  try:
    options, args = getopt.gnu_getopt(argv[1:], 'e:hv',
						   ['entry', 'help', 'version'])

    for opt, value in options:
      if opt in ('-e', '--entry'):
        entry = value
      elif opt in ('-h','--help'):
        print(_(__doc__).format(program_name))
        return 0
      elif opt in ('-v','--version'):
        print(_("{0} version: {1}").format(program_name, version))
        return 0
      else:
        print(_('{0}: invalid option: {1}').format(program_name, opt),
								file=sys.stderr)
        print(_('run {0} -h for help').format(program_name), file=sys.stderr)
        return 1
  except getopt.GetoptError as msg:
    print(_('{0}: invalid option: {1}').format(program_name, msg),
								file=sys.stderr)
    print(_('run {0} -h for help').format(program_name), file=sys.stderr)
    return 1

  if len(args) != 1:
    print(_('{0}: need exactly one ragel XML file').format(program_name),
								file=sys.stderr)
    print(_('run {0} -h for help').format(program_name), file=sys.stderr)
    return 1

  # Open file
  xmlfile = args[0]
  dfa_tree = etree.parse(xmlfile)

  # Find entry point
  if entry is None:
    entries = dfa_tree.xpath('//entry')
    if len(entries) != 1:
      print(_('{0}: «{1}» contains multiple entries and none are selected').
				 format(program_name, xmlfile), file=sys.stderr)
      print(_('run {0} -h for help').format(program_name), file=sys.stderr)
      return 1
  else:
    entries = dfa_tree.xpath('//entry[@name="'+entry+'"]')
    if len(entries) != 1:
      print(_('{0}: can not find entry «{2}» in «{1}»').
			  format(program_name, xmlfile, entry), file=sys.stderr)
      print(_('run {0} -h for help').format(program_name), file=sys.stderr)
      return 1
  entry = int(entries[0].text)

  print('	.text')
  return traverse_tree(xmlfile, read_trans_lists(xmlfile, dfa_tree), entry)

if __name__ == '__main__':
   exitcode = main(sys.argv)
   sys.exit(exitcode)
