#!/usr/bin/python

import os, sys
sys.path.append(os.path.abspath('./dotscad/'))
from dotscad import Customizer
import argparse

def norm(s):
    return s.replace('/', '-').replace('_','-')

def render_parts(basename, relativeTo=__file__):
    parser = argparse.ArgumentParser(
        description='Render STL from '+('' if basename is None else basename)+'.scad'
    )
    parser.add_argument("-u", "--update", action='store_true', default=False,
                        help="just update missing STL files")
    if basename is None:
        parser.add_argument('basename', metavar='basename.scad',
                            help="Name of scad file to render")
    args = parser.parse_args()
    if basename is None:
        basename = args.basename
    if basename.endswith('.scad'):
        basename = basename.rpartition('.')[0]

    os.chdir(os.path.dirname(os.path.abspath(relativeTo)))
    if not (args.update and os.path.isdir(basename + '-stl')):
      os.makedirs(basename + '-stl')
    s = Customizer(basename + '.scad', debug=False)
    for part in s.vars['part'].possible.parameters.keys():
        shortname = str(s.vars['part'].possible[part])
        s.vars['part'].set(shortname)
        name = '{0}-stl/{0}-{1}'.format(basename, norm(shortname))
        print name
        if (args.update and os.path.isfile(name + '.stl')):
          print "  (skipping, as it already exists)"
        else:
          s.render_stl(name + '.stl')

if __name__ == '__main__':
    render_parts(None)
