package it.uniba.di.support.structures;

import java.awt.geom.Line2D;
import java.awt.geom.Point2D;
import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

/**
 * <p>
 * Matrice di connettivita' triangolare superiore
 * </p>
 * 
 * @author Marco Pinto
 */


public class ConnectivityMatrix<T> {
	private T[] matrix;
	private int size;
	private T diagonalValue;
	private T defaultValue = null;

	/**
	 * 
	 * @param c
	 * @param size
	 * @param diagonalValue
	 * @param defaultValue
	 */
	public ConnectivityMatrix(Class<T> c, int size, T diagonalValue, T defaultValue) {
		this.diagonalValue = diagonalValue;
		initMatrix(c, size, defaultValue);
	}

	/**
	 * 
	 * @param c
	 * @param size
	 * @param diagonalValue
	 */
	public ConnectivityMatrix(Class<T> c, int size, T diagonalValue) {
		this.diagonalValue = diagonalValue;
		initMatrix(c, size);
	}

	/**
	 * 
	 * @param c
	 * @param size
	 * @param defaultValue
	 */
	private void initMatrix(Class<T> c, int size, T defaultValue) {
		int realSize = ((size * size) - size) / 2;
		T[] array = (T[]) (Array.newInstance(c, realSize));
		Arrays.fill(array, defaultValue);
		this.defaultValue = defaultValue;
		this.size = size;
		this.matrix = array;
	}

	/**
	 * 
	 * @param c
	 * @param size
	 */
	private void initMatrix(Class<T> c, int size) {
		int realSize = ((size * size) - size) / 2;
		T[] array = (T[]) (Array.newInstance(c, realSize));
		this.size = size;
		this.matrix = array;
	}

	/**
	 * 
	 * @param row
	 * @param column
	 * @param value
	 */
	public void insert(int row, int column, T value) {
		try {
			if (row < column) {
				matrix[(size * (size - 1) / 2) - (size - row) * ((size - row) - 1) / 2 + column - row - 1] = value;
			} else if (row == column) {
				matrix[(size * (size - 1) / 2) - (size - row) * ((size - row) - 1) / 2 + column - row
						- 1] = diagonalValue;
			} else {
				matrix[(size * (size - 1) / 2) - (size - column) * ((size - column) - 1) / 2 + row - column
						- 1] = value;
			}
		} catch (ArrayIndexOutOfBoundsException ex) {
			System.out.println("Row:" + row + ",Column:" + column);
			ex.printStackTrace();
		}
	}

	/**
	 * 
	 * @param row
	 * @param column
	 * @return
	 */
	public T get(int row, int column) {
		if (row == column)
			return diagonalValue;

		try {
			if (row < column) {
				return matrix[(size * (size - 1) / 2) - (size - row) * ((size - row) - 1) / 2 + column - row - 1];
			} else {
				return matrix[(size * (size - 1) / 2) - (size - column) * ((size - column) - 1) / 2 + row - column - 1];
			}
		} catch (ArrayIndexOutOfBoundsException ex) {
			ex.printStackTrace();
		}
		return defaultValue;
	}
	//bfs usata per trovare il percorso più breve
	
	private class item_c<T>{
	    private char color;
	    private int d ;
	    private  int parent;
	    item_c(){
	       color = 'w';
	 	   d = -1;
	 	   parent = -1;
	    }
	}
	// bfs from introduction to algorithms cormen, leiserson, rivest, stein 
	private item_c[] buildtree(int start){
		item_c<T> explored[] = new item_c[this.size];
		for (int i = 0; i < this.size; i++){
			explored[i] = new item_c ();
		}
		int nodo;

		LinkedList <Integer> frontier = new LinkedList<Integer> ();
		explored[start].color = 'g';
		explored[start].d = 0;
		explored[start].parent = -1;
		frontier.addLast(start);
		
		while(!frontier.isEmpty()) {
			nodo = frontier.pop();
			//controlla se i nodi adiacenti sono goal e li aggiuge alla frontier
			for (int j = 0; j < this.size; j++) {
				if(get(nodo, j) != defaultValue) {
				   if(explored[j].color == 'w') {
					   explored[j].color = 'g';
					   explored[j].d = explored[nodo].d + 1 ;
					   explored[j].parent = nodo;
					   frontier.addLast(j);
				   }
				}
			}
			explored[nodo].color = 'b';
		}
		return explored;
	}
  
	//risale l'albero costruito dal grafo per trovare il percorso da start a end
	private void findpath (int start,int end, item_c [] tree,LinkedList<Integer> path) {
		
		if (end == start){
			
			//path.addLast(start + 1);
			
		}else if (tree[end].parent == -1) {
			
			path = null;
		}else {
			findpath(start,tree[end].parent,tree,path);
			path.addLast(end + 1);
		}
		
	}
	// la numerazione degli host nel path parte da 1
	public LinkedList<Integer> findRoute(int start,int end) {
		LinkedList<Integer> path = new LinkedList<Integer> ();
		start = start - 1;
		end = end - 1;
		findpath(start,end,buildtree(start),path);
		return path;
	}
	
	/**
	 * 
	 */
	@Override
	public String toString() {
		return Arrays.toString(matrix);
	}

	/**
	 * 
	 * @param c
	 * @return
	 */
	public T[] deepCopy(Class<T> c) {
		int realSize = ((size * size) - size) / 2;
		T[] array = (T[]) (Array.newInstance(c, realSize));
		for (int i = 0; i < realSize; i++) {
			array[i] = matrix[i];
		}
		return array;
	}
}
