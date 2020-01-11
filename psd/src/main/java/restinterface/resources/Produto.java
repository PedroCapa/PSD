package main.java.restinterface.resources;

public class Produto{
	private String product_name;
	private String negotiator_name;
	private int min;
	private int max;
	private int price;

	public Produto(String product_name, String negotiator_name, int min, int max, int price){
		this.product_name = product_name;
		this.negotiator_name = negotiator_name;
		this.min = min;
		this.max = max;
		this.price = price;
	}

	public String getProduct_name(){
		return this.product_name;
	}

	public String getNegotiator_name(){
		return this.negotiator_name;
	}

	public int getMin(){
		return this.min;
	}

	public int getMax(){
		return this.max;
	}

	public int getPrice(){
		return this.price;
	}
}