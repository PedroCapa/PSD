package restinterface.resources;

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
}