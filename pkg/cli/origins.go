//  Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

package cli

import (
	"sort"

	"github.com/makerdao/gofer/pkg/gofer"
	"github.com/makerdao/gofer/pkg/graph"
)

func Origins(args []string, l gofer.PriceModels, m itemWriter) error {
	pairs, err := graph.Pairs(l, args...)
	if err != nil {
		return err
	}

	origins, err := l.Origins(pairs...)
	if err != nil {
		return err
	}

	for _, p := range sortMapKeys(origins) {
		err = m.Write(map[graph.Pair][]string{p: origins[p]})
		if err != nil {
			return err
		}
	}

	return nil
}

func sortMapKeys(m map[graph.Pair][]string) []graph.Pair {
	var pairs []graph.Pair
	for p := range m {
		pairs = append(pairs, p)
	}

	sort.Slice(pairs, func(i, j int) bool {
		return pairs[i].String() < pairs[j].Quote
	})

	return pairs
}
