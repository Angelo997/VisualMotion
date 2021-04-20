package it.uniba.di.support.structures;

import java.lang.reflect.Array;
import java.util.Arrays;

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
