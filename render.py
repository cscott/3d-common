#!/usr/bin/python

import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'dotscad'))
from dotscad import Customizer
import argparse
import itertools

def norm(s):
    return str(s).replace('/', '-').replace('_','-')

def render_parts(basename, keys=['part'], relativeTo=None):
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
    if relativeTo is None:
        try:
            import inspect
            frm = inspect.currentframe(1)
            relativeTo = inspect.getabsfile(frm)
        except:
            pass
    if relativeTo is None:
        relativeTo = __file__

    os.chdir(os.path.dirname(os.path.abspath(relativeTo)))
    if not (args.update and os.path.isdir(basename + '-stl')):
      if os.path.isdir(basename + '-stl'):
        print >> sys.stderr, "FAILED: Directory " + basename + "-stl already exists. (Use -u to update.)"
        sys.exit(1)
      os.makedirs(basename + '-stl')
    s = Customizer(basename + '.scad', debug=False)
    for p in itertools.product(*[s.vars[y].possible.parameters.keys() for y in keys]):
        p2 = [{
            'key':x[0],
            'part':x[1],
            'shortname':s.vars[x[0]].possible[x[1]]
        } for x in zip(keys, p)]
        name = '{0}-stl/{0}'.format(basename)
        for d in p2:
            s.vars[d['key']].set(d['shortname'])
            name += '-{0}'.format(norm(d['shortname']))
        print name
        if (args.update and os.path.isfile(name + '.stl')):
          print "  (skipping, as it already exists)"
        else:
          s.render_stl(name + '.stl')

if __name__ == '__main__':
    render_parts(None)
