package restinterface.resources;

public class Negocio{
	private String client_offer;
	private String fab;
	private String prod;
	private int price;
	private int amount;

	public Negocio(String client_offer, String fab, String prod, int price, int amount){
		this.fab = fab;
		this.client_offer = client_offer;
		this.prod = prod;
		this.price = price;
		this.amount = amount;
	}

	public String getFab(){
		return this.fab;
	}

	public String getClient_offer(){
		return this.client_offer;
	}

	public String getProd(){
		return this.prod;
	}

	public int getPrice(){
		return this.price;
	}

	public int getAmount(){
		return this.amount;
	}
}